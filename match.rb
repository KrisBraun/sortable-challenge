#!/usr/bin/env ruby
# coding: utf-8

# Requires Ruby 1.9 for JSON library

require 'json'

# normalize strings for comparison by filtering out non-alpha-numeric characters
# note: this includes spaces!
class String
  def normalize
    self.gsub(/[^a-zA-Z1-90]/,'').downcase
  end
end

# read products into a hash of hashes; products[manufacturer][model]
products = Hash.new{ |hash, key| hash[key] = Hash.new }
File.open('products.txt', 'r') do |file|
  file.each do |line|
    product = JSON.parse(line)
    # first word is unique enough and avoids minor differences (e.g. country
    # names)
    manufacturer = product['manufacturer'].split.first.normalize
    next if manufacturer.empty?
    # only keep necessary info in memory; family name would provide negligible
    # matching value since we need to match the model name, too
    products[manufacturer][product['model'].normalize] = product['product_name']
  end
end

# put matching listings into arrays in a hash indexed by product name
matches = Hash.new{ |hash, key| hash[key] = Array.new }
File.open('listings.txt', 'r') do |file|
  file.each do |line|
    listing = JSON.parse(line)
    next if not listing.key? 'title'

    # find the array of models for the given manufacturer; if the explicit
    # manufacturer isn't set or isn't found, try the first word of the title
    manufacturer = nil
    manufacturer_models = nil
    [ listing['manufacturer'], listing['title'] ].each do |entry|
      next if entry.empty?
      manufacturer = entry.split.first.normalize
      if products.key? manufacturer
        manufacturer_models = products[manufacturer]
        break
      end
    end
    next if manufacturer_models.nil?

    # loop through the words in the title, looking for model name matches
    match = ""
    last_word = ""
    listing['title'].split.each do |word|
      # stop searching if this is an accessory for another product
      # this is a little fragile (needs words added for new languages), but
      # quite efficient and effective
      break if /for|pour|für/i.match word
      word = word.normalize
      # check against manufacturer to avoid at least one hash lookup per listing
      next if word.empty? or word == manufacturer
      # try model composed of two words first to get more specific matches
      # (e.g. WG-1 GPS vs. WG-1, Mju-9010 vs. 9010)
      product = manufacturer_models[last_word + word]
      if product.nil?
        # if the last word was a match but the last word plus this one isn't,
        # go with the last word
        break if not match.empty?
        product = manufacturer_models[word] if product.nil?
        last_word = word
      else
        last_word += word
      end
      match = product if product
    end
    matches[match].push listing if not match.empty?
  end
end

# print result objects
matches.each do |product, listings|
  result = {product_name: product, listings: listings}
  print JSON.generate result
  print "\n"
end
