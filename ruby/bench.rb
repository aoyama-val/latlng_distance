require "benchmark"
require "vincenty"
require_relative "./calc_dist.rb"

Benchmark.bm 10 do |r|
  mode = 2
  lat1 = 35.65500
  lon1 = 139.74472
  lat2 = 36.10056
  lon2 = 140.09111

  TIMES = 100000

  obj_calc = CalcDist::Calc.new( mode, lat1, lon1, lat2, lon2 )
  r.report "haversine" do
    TIMES.times do
      dist = obj_calc.calc_haversine
    end
  end

  r.report "hubeny" do
    TIMES.times do
      dist = obj_calc.calc_hubeny
    end
  end

  v1 = Vincenty.new(lat1, lon1)
  v2 = Vincenty.new(lat2, lon2)
  r.report "vincenty" do
    TIMES.times do
      track_and_distance = v1.distanceAndAngle(v2)
      #puts track_and_distance.distance
    end
  end
end
