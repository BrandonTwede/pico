ruleset trip_store {
  meta {
    name "trip_store"
    description <<
Part 3, trip_store of the Pico Lab
>>
    author "Brandon Twede"
    logging on
    provides trips, long_trips, short_trips
    shares collect_trips, collect_long_trips, clear_trips, __testing, trips, long_trips, short_trips
  }
  
  global {
	  __testing = { "queries": [ 
                       { "name": "__testing" }, {"name":"long_trips"},{"name":"trips"}, {"name":"short_trips"} ],
          "events": [ { "domain": "car", "type": "new_trip","attrs": [ "mileage" ] }]
        }
    long_trip = 10
    trips = function(){
      ent:trips
    }
    long_trips = function(){
      ent:long_trips
    }
    short_trips = function(){
      //trips - long_trips
      short = ent:trips.filter(function(v,k){not (ent:long_trips >< k)});
      short
    }
    empty_store = {}
  }
  
  rule collect_trips {
    select when explicit trip_processed
    pre{
      miles = event:attr("mileage")
      timestamp = event:attr("timestamp")
    }
    always{
      ent:trips := ent:trips.defaultsTo(empty_store, "initialization was needed");
      ent:trips := ent:trips.put([timestamp], miles)
    }
  }
  
  rule collect_long_trips {
    select when explicit found_long_trip
    pre{
      miles = event:attr("mileage")
      //timestamp = time:now()
      timestamp = event:attr("timestamp")
    }
    always{
      ent:long_trips := ent:long_trips.defaultsTo(empty_store, "initialization was needed");
      ent:long_trips := ent:long_trips.put([timestamp], miles)
    }
  }
  
  rule clear_trips {
    select when car trip_reset
    always{
      ent:trips := {};
      ent:long_trips := {}
    }
  }
  
}