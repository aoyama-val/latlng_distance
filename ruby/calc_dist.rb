# -*- coding: utf-8 -*-
# 
# ２地点間の距離を計算（２地点の緯度・経度から）
#
# date          name            version
# 2011.10.22    mk-mode.com     1.00 新規作成
#
# Copyright(C)2011 mk-mode.com All Rights Reserved.
#---------------------------------------------------------------------------------
# 引数 : [第１] 測地系 ( 0:BESSEL , 1:GRS80 , 2:WGS84 )
#        [第２] 緯度１ (  -90.00000000 ～  90.00000000 )
#        [第３] 経度１ ( -180.00000000 ～ 180.00000000 )
#        [第４] 緯度２ (  -90.00000000 ～  90.00000000 )
#        [第５] 経度２ ( -180.00000000 ～ 180.00000000 )
#---------------------------------------------------------------------------------
# 備考 : 1:GRS80 が最も正確
#        島根原発１号機 ( 35.5382 132.9998 )
#        自宅           ( 99.9999 179.9999 )
#      : 完全な球だと想定すると
#        D = R * acos( sin(y1) * sin(y2) + cos(y1) * cos(y2) * cos(x2-x1) )
#++

class CalcDist
  # 使用方法
  USAGE =  "USAGE : ruby calc_disk.rb Type Lat1 Lon1 Lat2 Lon2\n"
  USAGE << "Type       : 0:BESSEL, 1:GRS80, 2:WGS84\n"
  USAGE << "Lat1, Lat2 :  -90.00000000 -  [+]90.00000000\n"
  USAGE << "Lon1, Lon2 : -180.00000000 - [+]180.00000000"

  # 定数 ( ベッセル楕円体 ( 旧日本測地系 ) )
  BESSEL_R_X  = 6377397.155000 # 赤道半径
  BESSEL_R_Y  = 6356079.000000 # 極半径

  # 定数 ( GRS80 ( 世界測地系 ) )
  GRS80_R_X   = 6378137.000000 # 赤道半径
  GRS80_R_Y   = 6356752.314140 # 極半径

  # 定数 ( WGS84 ( GPS ) )
  WGS84_R_X   = 6378137.000000 # 赤道半径
  WGS84_R_Y   = 6356752.314245 # 極半径

  # 定数 ( 測地系 )
  MODE = [ "BESSEL", "GRS-80", "WGS-84" ]

  # [CLASS] 引数
  class Arg
    # 引数チェック
    def check_arg()
      begin
        # 存在チェック
        return false unless ARGV.length == 5

        # 測地系タイプチェック
        unless ARGV[0] =~ /^[012]$/
          return false
        end

        # 緯度チェック
        unless ARGV[1] =~ /^[+|-]?(\d|[1-8]\d|90)(\.\d{1,8})?$/ &&
               ARGV[3] =~ /^[+|-]?(\d|[1-8]\d|90)(\.\d{1,8})?$/
          return false
        end

        # 経度チェック
        unless ARGV[2] =~ /^[+|-]?(\d{1,2}|1[0-7]\d|180)(\.\d{1,8})?$/ &&
               ARGV[4] =~ /^[+|-]?(\d{1,2}|1[0-7]\d|180)(\.\d{1,8})?$/
          return false
        end

        return true
      rescue => e
        # エラーメッセージ
        str_msg = "[EXCEPTION][" + self.class.name + ".check_arg] " + e.to_s
        STDERR.puts( str_msg )
        exit! 1
      end
    end
  end

  # [CLASS] 計算
  class Calc
    def initialize(mode, lat_1, lon_1, lat_2, lon_2)
      @mode  = mode
      @lat_1 = lat_1
      @lon_1 = lon_1
      @lat_2 = lat_2
      @lon_2 = lon_2
    end

    def calc_hubeny
      # 指定測地系の赤道半径・極半径を設定
      case @mode
      when 0
        r_x = BESSEL_R_X
        r_y = BESSEL_R_Y
      when 1
        r_x = GRS80_R_X
        r_y = GRS80_R_Y
      when 2
        r_x = WGS84_R_X
        r_y = WGS84_R_Y
      end

      # 2点の経度の差を計算 ( ラジアン )
      a_x = @lon_1 * Math::PI / 180.0 - @lon_2 * Math::PI / 180.0

      # 2点の緯度の差を計算 ( ラジアン )
      a_y = @lat_1 * Math::PI / 180.0 - @lat_2 * Math::PI / 180.0

      # 2点の緯度の平均を計算
      p = ( @lat_1 * Math::PI / 180.0 + @lat_2 * Math::PI / 180.0 ) / 2.0

      # 離心率を計算
      e = Math::sqrt( ( r_x ** 2 - r_y ** 2 ) / ( r_x ** 2 ).to_f )

      # 子午線・卯酉線曲率半径の分母Wを計算
      w = Math::sqrt( 1 - ( e ** 2 ) * ( ( Math::sin( p ) ) ** 2 ) )

      # 子午線曲率半径を計算
      m = r_x * ( 1 - e ** 2 ) / ( w ** 3 ).to_f

      # 卯酉線曲率半径を計算
      n = r_x / w.to_f

      # 距離を計算
      d  = ( a_y * m ) ** 2
      d += ( a_x * n * Math.cos( p ) ) ** 2
      d  = Math::sqrt( d )
      return d
    end

    def calc_haversine
      case @mode
      when 0
        r_x = BESSEL_R_X
        r_y = BESSEL_R_Y
      when 1
        r_x = GRS80_R_X
        r_y = GRS80_R_Y
      when 2
        r_x = WGS84_R_X
        r_y = WGS84_R_Y
      end
      # 地球を完全な球とみなした場合
      # ( 球面三角法 )
      # D = R * acos( sin(y1) * sin(y2) + cos(y1) * cos(y2) * cos(x2-x1) )
      d_1  = Math::sin( @lat_1 * Math::PI / 180.0 )
      d_1 *= Math::sin( @lat_2 * Math::PI / 180.0 )
      d_2  = Math::cos( @lat_1 * Math::PI / 180.0 )
      d_2 *= Math::cos( @lat_2 * Math::PI / 180.0 )
      d_2 *= Math::cos( @lon_2 * Math::PI / 180.0 - @lon_1 * Math::PI / 180.0 )
      d_0  = r_x * Math::acos( d_1 + d_2 ).to_f
    end

    # 距離計算
    def calc_dist
      begin
        d = calc_hubeny
        d_0 = calc_haversine

        return [ d, d_0 ]
      rescue => e
        # エラーメッセージ
        str_msg = "[EXCEPTION][" + self.class.name + ".calc_dist] " + e.to_s
        STDERR.puts( str_msg )
        exit 1
      end
    end
  end

  #### MAIN ####
  if __FILE__ == $0
    # 引数チェック( エラーなら終了 )
    obj_arg = Arg.new
    unless obj_arg.check_arg
      # エラーの場合、終了
      puts USAGE
      exit!
    end

    # 引数取得
    mode  = ARGV[0].to_i
    lat_1 = ARGV[1].to_f
    lon_1 = ARGV[2].to_f
    lat_2 = ARGV[3].to_f
    lon_2 = ARGV[4].to_f

    # 距離計算
    obj_calc = Calc.new( mode, lat_1, lon_1, lat_2, lon_2 )
    dist = obj_calc.calc_dist

    # 結果出力
    puts "Mode        : #{MODE[mode]}"
    puts "Latitude (1): #{sprintf("%13.8f",lat_1)} degrees"
    puts "Longitude(1): #{sprintf("%13.8f",lon_1)} degrees"
    puts "Latitude (2): #{sprintf("%13.8f",lat_2)} degrees"
    puts "Longitude(2): #{sprintf("%13.8f",lon_2)} degrees"
    puts "Distance = #{dist[0]} m ( #{dist[1]} m )"
  end
end
