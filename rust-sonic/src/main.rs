use std::env;
use std::fs;
use std::hint::black_box;
use std::path::PathBuf;
use std::time::{Duration, Instant};

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct Payload<'a> {
    dataset: &'a str,
    #[serde(rename = "generatedAt")]
    generated_at: &'a str,
    seed: u64,
    #[serde(rename = "itemCount")]
    item_count: u32,
    #[serde(rename = "variantCount")]
    variant_count: u32,
    #[serde(rename = "reviewCount")]
    review_count: u32,
    #[serde(borrow)]
    items: Vec<Item<'a>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Item<'a> {
    id: u32,
    sku: &'a str,
    name: &'a str,
    description: &'a str,
    price: f64,
    quantity: u32,
    active: bool,
    #[serde(borrow)]
    categories: Vec<&'a str>,
    #[serde(borrow)]
    tags: Vec<&'a str>,
    #[serde(borrow)]
    seller: Seller<'a>,
    dimensions: Dimensions,
    #[serde(borrow)]
    warehouse: Warehouse<'a>,
    #[serde(borrow)]
    attributes: Vec<Attribute<'a>>,
    #[serde(borrow)]
    variants: Vec<Variant<'a>>,
    #[serde(borrow)]
    reviews: Vec<Review<'a>>,
    #[serde(rename = "relatedIds")]
    related_ids: Vec<u32>,
    metrics: Metrics,
}

#[derive(Debug, Serialize, Deserialize)]
struct Seller<'a> {
    id: &'a str,
    name: &'a str,
    country: &'a str,
    rating: f64,
    priority: u8,
    #[serde(borrow)]
    contact: Contact<'a>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Contact<'a> {
    email: &'a str,
    phone: &'a str,
}

#[derive(Debug, Serialize, Deserialize)]
struct Dimensions {
    width: f64,
    height: f64,
    depth: f64,
    weight: f64,
}

#[derive(Debug, Serialize, Deserialize)]
struct Warehouse<'a> {
    id: &'a str,
    city: &'a str,
    aisle: &'a str,
    bin: &'a str,
    #[serde(rename = "temperatureControlled")]
    temperature_controlled: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct Attribute<'a> {
    name: &'a str,
    value: &'a str,
    score: f64,
}

#[derive(Debug, Serialize, Deserialize)]
struct Variant<'a> {
    id: &'a str,
    sku: &'a str,
    color: &'a str,
    size: &'a str,
    status: &'a str,
    #[serde(rename = "priceDelta")]
    price_delta: f64,
    stock: u32,
    barcode: &'a str,
    #[serde(borrow)]
    attributes: Vec<Attribute<'a>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Review<'a> {
    #[serde(rename = "userId")]
    user_id: &'a str,
    rating: u8,
    title: &'a str,
    body: &'a str,
    verified: bool,
    #[serde(rename = "helpfulVotes")]
    helpful_votes: u32,
    #[serde(rename = "createdAt")]
    created_at: &'a str,
}

#[derive(Debug, Serialize, Deserialize)]
struct Metrics {
    views: u64,
    sales: u64,
    returns: u64,
    #[serde(rename = "conversionRate")]
    conversion_rate: f64,
}

struct Stats {
    avg_ms: f64,
    min_ms: f64,
    max_ms: f64,
    throughput_mib_s: f64,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    let path = args
        .get(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("data/big.json"));
    let iterations = parse_arg(args.get(2), 10)?;
    let warmup = parse_arg(args.get(3), 3)?;

    let input = fs::read(&path)?;
    let input_len = input.len();
    let input_mib = input_len as f64 / (1024.0 * 1024.0);

    println!("runtime=rust-sonic");
    println!("file={}", path.display());
    println!("input_bytes={input_len}");
    println!("input_mib={input_mib:.3}");
    println!("iterations={iterations}");
    println!("warmup={warmup}");

    // --- warmup deserialization ---
    for _ in 0..warmup {
        let payload: Payload = sonic_rs::from_slice(&input)?;
        black_box(payload.items.len());
    }

    // --- benchmark deserialization (zero-copy: borrows from input) ---
    let mut deserialize_runs = Vec::with_capacity(iterations);
    for _ in 0..iterations {
        let started = Instant::now();
        let payload: Payload = black_box(sonic_rs::from_slice(black_box(&input))?);
        let elapsed = started.elapsed();
        black_box(&payload);
        deserialize_runs.push(elapsed);
    }
    let deserialize_stats = summarize(&deserialize_runs, input_len);

    // --- warmup serialization ---
    let payload: Payload = sonic_rs::from_slice(&input)?;
    let estimated_size = input_len + input_len / 8;
    let mut buf: Vec<u8> = Vec::with_capacity(estimated_size);
    for _ in 0..warmup {
        buf.clear();
        sonic_rs::to_writer(&mut buf, &payload)?;
        black_box(buf.len());
    }

    // --- benchmark serialization (reuse pre-allocated buffer) ---
    let mut serialize_runs = Vec::with_capacity(iterations);
    for _ in 0..iterations {
        buf.clear();
        let started = Instant::now();
        sonic_rs::to_writer(black_box(&mut buf), black_box(&payload))?;
        let elapsed = started.elapsed();
        black_box(buf.len());
        serialize_runs.push(elapsed);
    }
    let serialized_size = buf.len();
    let serialize_stats = summarize(&serialize_runs, serialized_size);

    print_stats("deserialize", &deserialize_stats);
    print_stats("serialize", &serialize_stats);
    println!("serialized_bytes={serialized_size}");

    Ok(())
}

fn parse_arg(value: Option<&String>, default: usize) -> Result<usize, Box<dyn std::error::Error>> {
    match value {
        Some(text) => Ok(text.parse()?),
        None => Ok(default),
    }
}

fn summarize(runs: &[Duration], bytes_per_op: usize) -> Stats {
    let min = runs.iter().copied().min().unwrap_or_default();
    let max = runs.iter().copied().max().unwrap_or_default();
    let total_secs: f64 = runs.iter().map(Duration::as_secs_f64).sum();
    let avg_secs = total_secs / runs.len() as f64;
    let throughput_mib_s = (bytes_per_op as f64 / (1024.0 * 1024.0)) / avg_secs;
    Stats {
        avg_ms: avg_secs * 1000.0,
        min_ms: min.as_secs_f64() * 1000.0,
        max_ms: max.as_secs_f64() * 1000.0,
        throughput_mib_s,
    }
}

fn print_stats(label: &str, stats: &Stats) {
    println!("{label}_avg_ms={:.3}", stats.avg_ms);
    println!("{label}_min_ms={:.3}", stats.min_ms);
    println!("{label}_max_ms={:.3}", stats.max_ms);
    println!("{label}_throughput_mib_s={:.3}", stats.throughput_mib_s);
}
