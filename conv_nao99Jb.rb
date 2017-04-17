
# load libraries
require "numru/gphys"
include NumRu
require "~/lib_k247/K247_basic"

# 2016-09-02: create
#   read nao99Jb_vel.txt & make NetCDF file

def conv_nDn_to_f( txt)
# conv "0.1603D+02" to float
  if txt == "0.0" 
    return txt.to_f
  else
    n, d = txt.split( "D" )
    return n.to_f * 10.0**d.to_f
  end
end

watcher = K247_Main_Watch.new

# Main 4 component tides
  tide_type = "m2" # M2: moon semi-diurnal
  #tide_type = "s2" # S2: sun semi-diurnal
  #tide_type = "k1" # K1: mixed diurnal
  #tide_type = "o1" # O1: moon diurnal

 # main 8
  #tide_type = "p1" # : diurnal
  #tide_type = "n2" # : diurnal
  #tide_type = "k2" # : diurnal
  #tide_type = "mf" # : 14day ( not included in nao99Jb)
  
 # main 16
  #tide_type = "q1" # : diurnal
  #tide_type = "m1" # : diurnal
  #tide_type = "j1" # : diurnal
  #tide_type = "oo1" # : diurnal
  #tide_type = "2n2" # : diurnal
  #tide_type = "l2" # : diurnal
  #tide_type = "mu2" # : diurnal
  #tide_type = "nu2" # : diurnal
  #tide_type = "t2" # : diurnal

  dname     = "nao99Jb"
  org_fn    = "#{dname}/#{tide_type}_j.xyap"
  puts "org_fn: #{org_fn}"
    # sorted lat downward
# nao99_Jb/
#   line
#     lon [deg], lat [deg], Amp [cm], Phs [deg]
#   ex.
#     164.3333  62.6667 146.9300 241.2200
#   details
#     lon: longitude  ( 110.0 to 165.0 , dx = 1/12)
#     lat: latitude   (  20.0 to 62.667, dy = 1/12)
#     Amp: Amplitude  (   )
#     Phs: Phase      ( Phase: Greenwich phase    )
#


# read file
lons = []; lats = []; amp = []; phs = []
File.open( org_fn, "r" ) do |fu|
  fu.each_line do | line |
    lo, la, am, ph = line.chomp.split( " " )
  #  dtypes << dt; lats << la; lons << lo; deps << dp
    lons << lo; lats << la
    amp << am; phs << ph
  end
end

# conv to NArray
lnum = lats.length
na_lons = NArray.sfloat( lnum ); na_lats = NArray.sfloat( lnum )
na_amp  = NArray.sfloat( lnum ); na_phs  = NArray.sfloat( lnum )
for n in 0..lnum-1
  na_lons[n] = lons[n].to_f
  na_lats[n] = lats[n].to_f
  na_amp[n]  = amp[n].to_f
  na_phs[n]  = phs[n].to_f
end
#  p na_amp.min
#  p na_amp.max
#  p na_phs.min
#  p na_phs.max
#  p na_lons.min
#  p na_lons.max
#  p na_lats.min
#  p na_lats.max



# set array
  lon_min = 110.0; lon_max = 165.0; dlon = 1.0 / 12.0
  lat_min =  20.0; lat_max =  63.0; dlat = 1.0 / 12.0
  nlon    = ( ( lon_max - lon_min ) / dlon ).to_i + 1
  nlat    = ( ( lat_max - lat_min ) / dlat ).to_i + 1
  lon_arr = lon_min + dlon * NArray.sfloat( nlon ).indgen 
  lat_arr = lat_min + dlat * NArray.sfloat( nlat ).indgen
  rmiss   = NArray.sfloat(1).fill( -999.9 )
  amp_arr  = NArray.sfloat( nlon, nlat ).fill( rmiss )
  phs_arr  = NArray.sfloat( nlon, nlat ).fill( rmiss )

  # set arr: preparation
  nbgn = NArray.int( nlat+1 ).fill( 0 )
  nend = NArray.int( nlat+1 ).fill( 0 )
  for n in 0..lnum-1
    i = ( (na_lats[n] - lat_min) / dlat ).round
    nend[i] = n
  end
  nbgn[ 0..nlat-5 ] = nend[ 1..nlat-4 ] + 1
  #p nbgn[ 0..5 ]
  #p nend[ 0..5 ]
  #p lat_arr[0..5]
  #p nbgn[   -9..-4 ]
  #p nend[   -9..-4 ]
  #p lat_arr[-9..-4]
  #p nbgn[   nlat-9..nlat-5 ]
  #p nend[   nlat-9..nlat-5 ]
  #p lat_arr[nlat-9..nlat-5]
  
  # set arr
  for j in 0..nlat-5
    for n in nbgn[j]..nend[j]
      i = ( ( na_lons[n] - lon_min ) / dlon ).round
      amp_arr[i,j] = na_amp[n]
      phs_arr[i,j] = na_phs[n]
    end
  end
  
  
=begin
  # fix grid
  #   Xu = X - 0.5 * dx; Yv = Y - 0.5 * dy
  for i in 0..nlon-2
  for j in 0..nlat-2
    #if ( au_arr[i,j] != rmiss ) and ( au_arr[i+1,j] != rmiss )
    if ( au_arr[i,j] >= 0.0 ) and ( au_arr[i+1,j] >= 0.0 )
      au_arr[i,j] = 0.5 * ( au_arr[i,j] + au_arr[i+1,j] )
      pu_arr[i,j] = 0.5 * ( pu_arr[i,j] + pu_arr[i+1,j] )
    end
    #if ( av_arr[i,j] != rmiss ) and ( av_arr[i,j+1] != rmiss )
    if ( av_arr[i,j] >= 0.0 ) and ( av_arr[i,j+1] >= 0.0 )
      av_arr[i,j] = 0.5 * ( av_arr[i,j] + av_arr[i,j+1] )
      pv_arr[i,j] = 0.5 * ( pv_arr[i,j] + pv_arr[i,j+1] )
    end
    #if ( au_arr[i,j] != rmiss ) and ( av_arr[i,j] != rmiss )
    if ( au_arr[i,j] >= 0.0 ) and ( av_arr[i,j] >= 0.0 )
      spd_arr[i,j] = sqrt( au_arr[i,j]**2.0 + av_arr[i,j]**2.0 ) 
    end
  end
  end
=end
# write nc
  ax_lon  = Axis.new.set_pos( VArray.new( lon_arr, { "long_name" => "longitude", "units" => "degE"}, "lon") )
  ax_lat  = Axis.new.set_pos( VArray.new( lat_arr, { "long_name" => "latitude" , "units" => "degN"}, "lat") )
  gr_xy   = Grid.new( ax_lon, ax_lat )
  att_amp  = { "long_name" => "Amplitude", "units" =>  "cm", "missing_value" => rmiss}
  att_phs  = { "long_name" => "Phase"    , "units" => "deg", "missing_value" => rmiss}
  out_fn = "#{dname}/#{tide_type}_j.nc"
  #out_fn = "tmp.nc"
  fu = NetCDF.create( out_fn )
  puts "out_fn: #{out_fn}"
    da_amp = VArray.new( amp_arr, att_amp, "amp" )
    gp_amp  = GPhys.new( gr_xy, da_amp )
    GPhys::NetCDF_IO.write( fu, gp_amp )
    da_phs = VArray.new( phs_arr, att_phs, "phs" )
    gp_phs  = GPhys.new( gr_xy, da_phs )
    GPhys::NetCDF_IO.write( fu, gp_phs )
  fu.close
=begin
=end

watcher.end_process
