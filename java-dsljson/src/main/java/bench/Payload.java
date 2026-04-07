package bench;

import com.dslplatform.json.CompiledJson;

import java.util.List;

@CompiledJson
public class Payload {
    public String dataset;
    public String generatedAt;
    public int seed;
    public int itemCount;
    public int variantCount;
    public int reviewCount;
    public List<Item> items;
}

@CompiledJson
class Item {
    public int id;
    public String sku;
    public String name;
    public String description;
    public double price;
    public int quantity;
    public boolean active;
    public List<String> categories;
    public List<String> tags;
    public Seller seller;
    public Dimensions dimensions;
    public Warehouse warehouse;
    public List<Attribute> attributes;
    public List<Variant> variants;
    public List<Review> reviews;
    public int[] relatedIds;
    public Metrics metrics;
}

@CompiledJson
class Seller {
    public String id;
    public String name;
    public String country;
    public double rating;
    public int priority;
    public Contact contact;
}

@CompiledJson
class Contact {
    public String email;
    public String phone;
}

@CompiledJson
class Dimensions {
    public double width;
    public double height;
    public double depth;
    public double weight;
}

@CompiledJson
class Warehouse {
    public String id;
    public String city;
    public String aisle;
    public String bin;
    public boolean temperatureControlled;
}

@CompiledJson
class Attribute {
    public String name;
    public String value;
    public double score;
}

@CompiledJson
class Variant {
    public String id;
    public String sku;
    public String color;
    public String size;
    public String status;
    public double priceDelta;
    public int stock;
    public String barcode;
    public List<Attribute> attributes;
}

@CompiledJson
class Review {
    public String userId;
    public int rating;
    public String title;
    public String body;
    public boolean verified;
    public int helpfulVotes;
    public String createdAt;
}

@CompiledJson
class Metrics {
    public long views;
    public long sales;
    public long returns;
    public double conversionRate;
}
