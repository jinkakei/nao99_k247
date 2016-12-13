
# load libraries
require "numru/gphys"
include NumRu
require "~/lib_k247/K247_basic"



watcher = K247_Main_Watch.new

# Main 4 component tides
  #tide_type = "m2" # M2: moon semi-diurnal
  #tide_type = "s2" # S2: sun semi-diurnal
  #tide_type = "k1" # K1: mixed diurnal
  tide_type = "o1" # O1: moon diurnal

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
  #tide_type = "mu2" # : diurnal
  #tide_type = "nu2" # : diurnal
  #tide_type = "l2" # : diurnal
  #tide_type = "mu2" # : diurnal
  #tide_type = "t2" # : diurnal

  dname     = "nao99Jb_vel"
  nc_fn    = "#{dname}/#{tide_type}.nc"
  puts "nc_fn : #{nc_fn}"
  vnames = [ "au", "av", "spd", "pu", "pv" ]

  # lon, lat max min
  #  lon_min = 110.0; lon_max = 165.0; dlon = 1.0 / 12.0
  #  lat_min =  20.0; lat_max =  63.0; dlat = 1.0 / 12.0

# set region  
  # near otsuchi
    xmin  = 141.0; xmax = 144.0
    ymin  =  38.0; ymax =  40.0
    rname = "#{xmin.to_i}to#{xmax.to_i}E_#{ymin.to_i}to#{ymax.to_i}N"
  # 
    xname = "lon"; yname = "lat"
    xrng = xmin..xmax
    yrng = ymin..ymax

out_fn = "#{dname}/cut_#{tide_type}_#{rname}.nc"
out_fu = NetCDF.create( out_fn )
  puts "out_fn: #{out_fn}"
  vnames.each do | vn |
    gp_var = GPhys::IO.open( nc_fn, vn )
    GPhys::NetCDF_IO.write( out_fu, gp_var.cut( xname => xrng, yname => yrng ) )
  end
out_fu.close
=begin
=end

watcher.end_process
