require "benchmark"
require "vincenty"
require_relative "./calc_dist.rb"

Benchmark.bm 10 do |r|
  mode = 2
  #lat1, lon1 = 35.681741, 139.762254
  #lat2, lon2 = 35.681625, 139.762238
  # 東京
  lat1 = 35.65500
  lon1 = 139.74472
  # 筑波
  lat2 = 36.10056
  lon2 = 140.09111

  TIMES = 100000

  obj_calc = CalcDist::Calc.new( mode, lat1, lon1, lat2, lon2 )
  r.report "haversine" do
    TIMES.times do |i|
      dist = obj_calc.calc_haversine
      puts "haversine = #{dist}" if i == 0
    end
  end

  r.report "hubeny" do
    TIMES.times do |i|
      dist = obj_calc.calc_hubeny
      puts "hubeny = #{dist}" if i == 0
    end
  end

  v1 = Vincenty.new(lat1, lon1)
  v2 = Vincenty.new(lat2, lon2)
  r.report "vincenty" do
    TIMES.times do |i|
      track_and_distance = v1.distanceAndAngle(v2)
      puts "vincenty = #{track_and_distance.distance}" if i == 0
    end
  end
end
