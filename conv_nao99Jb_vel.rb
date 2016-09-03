
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

  dname     = "nao99Jb_vel"
  org_fn    = "#{dname}/vfield.#{tide_type}"
  puts "org_fn: #{org_fn}"
# nao99_Jb_vel
#   line
#     lon [deg], lat [deg], Au [cm/s], Pu [deg], Av [cm/s], Pv[deg]
#   ex.
#     164.417  62.667 0.1603D+02 0.2519D+03 0.1267D+02 0.2086D+03
#   details
#     lon: longitude      ( 110.0 to 165.0 , dx = 1/12)
#     lat: latitude       (  20.0 to 62.667, dy = 1/12)
#      Au: Amplitude of u ( u    : eastward velocity  )
#      Pu:     phase of u ( Phase: Greenwich phase    )
#      Av: Amplitude of v ( v    : northward velocity )
#      Pv:     phase of v 
#

# sort
  sorted_fn   = "#{dname}/sorted_#{tide_type}.txt"
  system( "sort #{org_fn} > #{sorted_fn}")

# read file
lons = []; lats = []; amp_u = []; pha_u = []; amp_v = []; pha_v = []
File.open( sorted_fn , "r" ) do |fu|
  fu.each_line do | line |
    lo, la, au, pu, av, pv = line.chomp.split( " " )
  #  dtypes << dt; lats << la; lons << lo; deps << dp
    lons << lo; lats << la
    amp_u << au; pha_u << pu; amp_v << av; pha_v << pv
  end
end

# conv to NArray
lnum = lats.length
na_lons = NArray.sfloat( lnum ); na_lats = NArray.sfloat( lnum )
na_au   = NArray.sfloat( lnum ); na_pu   = NArray.sfloat( lnum )
na_av   = NArray.sfloat( lnum ); na_pv   = NArray.sfloat( lnum )
for n in 0..lnum-1
  na_lons[n] = lons[n].to_f
  na_lats[n] = lats[n].to_f
  na_au[n]   = conv_nDn_to_f( amp_u[n] )
  na_pu[n]   = conv_nDn_to_f( pha_u[n] )
  na_av[n]   = conv_nDn_to_f( amp_v[n] )
  na_pv[n]   = conv_nDn_to_f( pha_v[n] )
end
  #p na_pv.min



# set
  lon_min = 110.0; lon_max = 165.0; dlon = 1.0 / 12.0
  lat_min =  20.0; lat_max =  63.0; dlat = 1.0 / 12.0
  nlon    = ( ( lon_max - lon_min ) / dlon ).to_i + 1
  nlat    = ( ( lat_max - lat_min ) / dlat ).to_i + 1
  lon_arr = lon_min + dlon * NArray.sfloat( nlon ).indgen 
  lat_arr = lat_min + dlat * NArray.sfloat( nlat ).indgen
  rmiss   = NArray.sfloat(1).fill( -999.9 )
  au_arr  = NArray.sfloat( nlon, nlat ).fill( rmiss )
  av_arr  = NArray.sfloat( nlon, nlat ).fill( rmiss )
  spd_arr = NArray.sfloat( nlon, nlat ).fill( rmiss )
  pu_arr  = NArray.sfloat( nlon, nlat ).fill( rmiss )
  pv_arr  = NArray.sfloat( nlon, nlat ).fill( rmiss )


  nbgn = NArray.int( nlon+1 ).fill( 0 )
  nend = NArray.int( nlon+1 ).fill( 0 )
  for n in 0..lnum-1
    i = ( (na_lons[n] - lon_min) / dlon ).round
    nend[i] = n
  end
  nbgn[ 1..nlon-1 ] = nend[ 0..nlon-2 ] + 1


=begin
  # check data
  File.open( "tmp_lon.txt", "w" ) do | fu |
    for n in 0..nlon-1
      for n2 in nbgn[i]..nend[i]
        fu.puts( na_lons[ n2  ])
      end
    end
  end
=end


for i in 0..nlon-1
  for n in nbgn[i]..nend[i]
    j = ( ( na_lats[n] - lat_min ) / dlat ).round
    au_arr[i,j]  = na_au[n]
    av_arr[i,j]  = na_av[n]
    spd_arr[i,j] = sqrt( na_au[n]**2.0 + na_av[n]**2.0 )
    pu_arr[i,j]  = na_pu[n]
    pv_arr[i,j]  = na_pv[n]
  end
end


ax_lon  = Axis.new.set_pos( VArray.new( lon_arr, { "long_name" => "longitude", "units" => "degE"}, "lon") )
ax_lat  = Axis.new.set_pos( VArray.new( lat_arr, { "long_name" => "latitude" , "units" => "degN"}, "lat") )
gr_xy   = Grid.new( ax_lon, ax_lat )
att_au  = { "long_name" => "Amplitude of u", "units" => "cm.s-1", "missing_value" => rmiss}
att_av  = { "long_name" => "Amplitude of v", "units" => "cm.s-1", "missing_value" => rmiss}
att_spd = { "long_name" => "Value of Speed", "units" => "cm.s-1", "missing_value" => rmiss, "comment" => "sqrt( au^2 + av^2 )"}
att_pu  = { "long_name" => "Phase of u"    , "units" => "deg", "missing_value" => rmiss}
att_pv  = { "long_name" => "Phase of v"    , "units" => "deg", "missing_value" => rmiss}
out_fn = "#{dname}/#{tide_type}.nc"
#out_fn = "tmp.nc"
fu = NetCDF.create( out_fn )
puts "out_fn: #{out_fn}"
  da_au  = VArray.new( au_arr, att_au, "au" )
  gp_au  = GPhys.new( gr_xy, da_au )
  GPhys::NetCDF_IO.write( fu, gp_au )
  da_av  = VArray.new( av_arr, att_av, "av" )
  gp_av  = GPhys.new( gr_xy, da_av )
  GPhys::NetCDF_IO.write( fu, gp_av )
  da_spd = VArray.new( spd_arr, att_spd, "spd" )
  gp_spd = GPhys.new( gr_xy, da_spd )
  GPhys::NetCDF_IO.write( fu, gp_spd )
  da_pu  = VArray.new( pu_arr, att_pu, "pu" )
  gp_pu  = GPhys.new( gr_xy, da_pu )
  GPhys::NetCDF_IO.write( fu, gp_pu )
  da_pv  = VArray.new( pv_arr, att_pv, "pv" )
  gp_pv  = GPhys.new( gr_xy, da_pv )
  GPhys::NetCDF_IO.write( fu, gp_pv )
fu.close
=begin
=end

# 
#  system( "rm #{sorted_fn}" )

watcher.end_process
