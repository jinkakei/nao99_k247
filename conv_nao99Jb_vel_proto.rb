
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

#tide_type = "m2"
tide_type = "s2"
org_fn = "nao99Jb_vel/vfield.#{tide_type}"
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

# read file
lons = []; lats = []; amp_u = []; pha_u = []; amp_v = []; pha_v = []
File.open( org_fn , "r" ) do |fu|
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
  au_arr  = NArray.sfloat( nlon, nlat ).fill( 0.0 )

i_x = Array( nlon )
i_y = Array( nlat )
for i in 0..nlon-1
#for i in 0..10
  i_x[i] = ( na_lons[ 0..-1 ] - lon_arr[i] ).abs.le( 0.5 * dlon )
end # for i in 0..n_x-1
for j in 0..nlat-1
#for j in 0..10
  i_y[j] = ( na_lats[ 0..-1 ] - lat_arr[j] ).abs.le( 0.5 * dlat )
end # for j in 0..n_y-1

for i in 0..nlon-1
for j in 0..nlat-1
#for i in 0..10
#for j in 0..10
  if ( i_x[i] * i_y[j] ).sum != 0
    au_arr[i,j] = na_au[ i_x[i] * i_y[j] ].mean
  end # if ( i_x[i] * i_y[j] ).sum != 0
end # for j in 0..n_y-1
end # for i in 0..n_x-1
  p au_arr.max

ax_lon = Axis.new.set_pos( VArray.new( lon_arr, \
           { "long_name" => "longitude", "units" => "degE"}, "lon") )
ax_lat = Axis.new.set_pos( VArray.new( lat_arr, \
           { "long_name" => "latitude" , "units" => "degN"}, "lat") )
da_au  = VArray.new( au_arr, \
                    { "long_name" => "Amplitude of u", "units" => "cm.s-1"}, "au")
gp_au  = GPhys.new( Grid.new( ax_lon, ax_lat ), da_au )

fu = NetCDF.create( "#{tide_type}.nc" )
GPhys::NetCDF_IO.write( fu, gp_au )
fu.close
=begin
=end

watcher.end_process
