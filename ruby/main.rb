require "vincenty"
require_relative "./calc_dist.rb"

puts "Usage: #{$0} lat1 lng1 lat2 lng2"

lat1 = ARGV[0].to_f
lon1 = ARGV[1].to_f
lat2 = ARGV[2].to_f
lon2 = ARGV[3].to_f

obj_calc = CalcDist::Calc.new( 2, lat1, lon1, lat2, lon2 )

v1 = Vincenty.new(lat1, lon1)
v2 = Vincenty.new(lat2, lon2)

track_and_distance = v1.distanceAndAngle(v2)
diff = 0
puts "vincenty  = #{sprintf("%.6f", track_and_distance.distance)} (#{sprintf("%.6f", diff)})"

dist = obj_calc.calc_haversine
diff = dist - track_and_distance.distance 
puts "haversine = #{sprintf("%.6f", dist)} (#{sprintf("%.6f", diff)})"

dist = obj_calc.calc_hubeny
diff = dist - track_and_distance.distance 
puts "hubeny    = #{sprintf("%.6f", dist)} (#{sprintf("%.6f", diff)})"
