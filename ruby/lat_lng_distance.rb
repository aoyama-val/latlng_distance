begin
  require "vincenty"
rescue LoadError
  # do nothing
end

# 緯度経度から距離を求めるためのクラス
# 単位は全てメートル
module LatLngDistance
  DEG2RAD = Math::PI / 180.0
  RAD2DEG = 180.0 / Math::PI

  # ベッセル楕円体（ 旧日本測地系）
  BESSEL_R_X  = 6377397.155000 # 赤道半径
  BESSEL_R_Y  = 6356079.000000 # 極半径

  # GRS80（世界測地系）
  GRS80_R_X   = 6378137.000000 # 赤道半径
  GRS80_R_Y   = 6356752.314140 # 極半径

  # WGS84（GPS）
  WGS84_R_X   = 6378137.000000 # 赤道半径
  WGS84_R_Y   = 6356752.314245 # 極半径

  @algorithm = :hubeny  # デフォルトのアルゴリズム
  @gcs = 2  # 測地系
  @cache = {}

  # デフォルトのアルゴリズムをセット
  def self.algorithm=(algorithm)
    @algorithm = algorithm
  end

  def self.algorithm
    return @algorithm
  end

  # 指定したアルゴリズムで距離を計算して返す
  def self.distance(lat1, lng1, lat2, lng2, algorithm=nil)
    if algorithm.nil?
      algorithm = @algorithm
    end

    # 2016-08-19 aoyama
    # 計測してみたところ、このキャッシュヒット率はかなり高かった（60%程度）
    # しかしその割にCSV変換には全然速度改善がなかった
    # それでもとりあえず入れておく
    key = "#{lat1},#{lng1},#{lat2},#{lng2},#{algorithm}"
    if @cache.key?(key)
      #puts "cache HIT! #{key}"
      return @cache[key]
    else
      #puts "cache NOT HIT! #{key}"
    end

    case algorithm
    when :euclid
      distance = self.euclid(lat1, lng1, lat2, lng2)
    when :haversine
      distance = self.haversine(lat1, lng1, lat2, lng2)
    when :hubeny
      distance = self.hubeny(lat1, lng1, lat2, lng2)
    when :vincenty
      distance = self.vincenty(lat1, lng1, lat2, lng2)
    else
      raise "未知のalgorithm: #{algorithm}"
    end

    @cache[key] = distance
    return distance
  end

  # ユークリッド距離を微調整する方法
  # 緯度・経度の差から距離を計算する近似式｜猫ですまんかった
  # http://ameblo.jp/nukopoint/entry-11426918282.html 
  def self.euclid(lat1, lng1, lat2, lng2)
    return Math::hypot((lat1 - lat2) * 111000, (lng1 - lng2) * 91000)
  end

  # 地球を完全な球とみなす方法
  def self.haversine(lat1, lng1, lat2, lng2)
    lat1 *= DEG2RAD
    lat2 *= DEG2RAD
    lng1 *= DEG2RAD
    lng2 *= DEG2RAD
    # D = R * acos( sin(y1) * sin(y2) + cos(y1) * cos(y2) * cos(x2-x1) )
    d1  = Math::sin(lat1) * Math::sin(lat2)
    d2  = Math::cos(lat1) * Math::cos(lat2) * Math::cos(lng2 - lng1)
    d0  = r_x * Math::acos(d1 + d2)
    return d0
  end

  # ヒュベニの公式
  # http://www.mk-mode.com/octopress/2011/10/28/28002050/
  # http://tancro.e-central.tv/grandmaster/excel/hubenystandard.html
  # http://yamadarake.jp/trdi/report000001.html
  def self.hubeny(lat1, lng1, lat2, lng2)
    # 指定測地系の赤道半径・極半径を設定

    lat1 *= DEG2RAD
    lat2 *= DEG2RAD
    lng1 *= DEG2RAD
    lng2 *= DEG2RAD

    # 2点の経度の差を計算 ( ラジアン )
    a_x = lng1 - lng2

    # 2点の緯度の差を計算 ( ラジアン )
    a_y = lat1 - lat2

    # 2点の緯度の平均を計算
    p = ( lat1 + lat2 ) / 2.0

    # 離心率を計算
    e = Math::sqrt( ( r_x ** 2 - r_y ** 2 ) / ( r_x ** 2 ) )

    # 子午線・卯酉線曲率半径の分母Wを計算
    w = Math::sqrt( 1 - ( e ** 2 ) * ( ( Math::sin( p ) ) ** 2 ) )

    # 子午線曲率半径を計算
    m = r_x * ( 1 - e ** 2 ) / ( w ** 3 )

    # 卯酉線曲率半径を計算
    n = r_x / w

    # 距離を計算
    d = ( a_y * m ) ** 2
    d += ( a_x * n * Math.cos( p ) ) ** 2
    d = Math::sqrt( d )
    return d
  end

  # Vincentyのアルゴリズム
  def self.vincenty(lat1, lng1, lat2, lng2)
    if not defined?(Vincenty)
      raise "vincentyが読み込まれていません。gem intall vincentyでインストールしてください。"
    end
    return Vincenty.new(lat1, lng1).distanceAndAngle(Vincenty.new(lat2, lng2)).distance
  end

  def self.r_x
    case @gcs
    when 0
      r_x = BESSEL_R_X
    when 1
      r_x = GRS80_R_X
    when 2
      r_x = WGS84_R_X
    end
    return r_x
  end

  def self.r_y
    case @gcs
    when 0
      r_y = BESSEL_R_Y
    when 1
      r_y = GRS80_R_Y
    when 2
      r_y = WGS84_R_Y
    end
    return r_y
  end

end

if __FILE__ == $0
  require "benchmark"

  TIMES = 100000
  puts "TIMES = #{TIMES}"

  Benchmark.bm 10 do |r|
    # 東京
    lat1 = 35.65500
    lng1 = 139.74472
    # 筑波
    lat2 = 36.10056
    lng2 = 140.09111

    methods = ["euclid", "haversine", "hubeny"]
    if defined?(Vincenty)
      methods << "vincenty"
    end
    methods.each do |method|
      r.report method do
        TIMES.times do |i|
          dist = LatLngDistance.send(method, lat1, lng1, lat2, lng2)
          puts dist if i == 0
        end
      end
    end
  end
end
