#!/usr/bin/ruby
# fapi.rb - playing around with sinatra/sequel

require 'json'
require 'sequel'
require 'sinatra'

## setup the DB
db = Sequel.connect('sqlite://fapi.db')

class Animals < Sequel::Model
  attr_accessor :created, :name, :type
  set_primary_key [:name]

  def initialize(name)
    @created = Time.now
    @name    = name
    @type    = self.class.to_s

    # TODO is this the right way? or should there be some magic?
    #self.insert(:name => self.name, :created => Time.now, :updated => Time.now)
  end

  def to_s
    {:type => self.class, :name => @name, :created => @created}.to_s
  end
end

class Lion < Animals; end
class Tiger < Animals; end
class Bear < Animals; end

# create a table if necessary
db.create_table? :animals do
  primary_key :id
  String :name
  String :type
  Date :created
  Date :updated
end

animals = db[:animals]

# seed with some data
if animals.all.empty?
  [
    Lion.new('harold'),
    Tiger.new('claude'),
    Bear.new('jason'),
  ].each do |animal|
    # TODO don't want to have to do anything here either, object instantiation should create the records
    animals.insert(
      :name    => animal.name,
      :type    => animal.type,
      :created => animal.created,
      :updated => Time.now
    )
  end

end

## routes

get '/api/animals' do
  content_type 'application/json'
  animals.all.to_json
end

get '/api/animals/:kind' do |kind|
  content_type 'application/json'
  animals.where(:class => kind).all.to_json
end

post '/api/animals' do
  name = params['name']
  kind = params['kind'].to_sym

  animal = nil

  if kind.eql?(:Lion)
    animal = Lion.new(name)
  elsif kind.eql?(:Tiger)
    animal = Tiger.new(name)
  else
    animal = Bear.new(name)
  end

  # .. don't want to have to manually create these.. this should be done in object initalization
  animals.insert(:name => animal.name, :created => animal.created, :updated => Time.now)

  status 201
  animals.to_json
end

delete '/api/animals' do
  name = params['name']

  if animals.where(:name => name)
    animals.each { |a| animals.delete(a) if a.name.eql?(name) }
    status 201
    animals.to_json
  else
    status 400
    {:error => sprintf('animal[%s] not found', name)}.to_json
  end

end


