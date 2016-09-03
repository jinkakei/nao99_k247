

# load libraries
require "numru/gphys"
include NumRu
require "~/lib_k247/K247_basic"

# 2016-09-03: create
#   tide speed vs depth ( jegg500 )


# Main 4 component tides
  tide_type = "m2" # M2: moon semi-diurnal
  #tide_type = "s2" # S2: sun semi-diurnal
  #tide_type = "k1" # K1: mixed diurnal
  #tide_type = "o1" # O1: moon diurnal

  dname   = "nao99Jb_vel"
    xmin  = 141.0; xmax = 144.0
    ymin  =  38.0; ymax =  40.0
    rname = "#{xmin.to_i}to#{xmax.to_i}E_#{ymin.to_i}to#{ymax.to_i}N"
  tide_nf = "#{dname}/cut_#{tide_type}_#{rname}.nc"
  puts "tide_nf : #{tide_nf}"
  #vname = "spd" # "au", "av", "spd", "pu", "pv"
  vname = [ "au", "av", "spd" ]
  

# depth
  dep_nf = "#{dname}/jegg500_#{rname}.nc"
  # from jegg_k247
  puts "dep_nf  : #{dep_nf}"
  vdep = "depth"
  dvar = GPhys::IO.open( dep_nf, vdep )
  

# 
  gxmin = 141.5; gxmax = 142.5; gymin = 38.75; gymax = 39.75
  #gxmin = 141.0; gxmax = 144.0; gymin =  38.0; gymax =  40.0
  #clevs = NArray.sfloat( 9 ).indgen
  #clevs = 0.1 * NArray.sfloat( 11 ).indgen + 1.0
  #clevs = 0.1 * NArray.sfloat( 11 ).indgen + 0.5
  clevs = 0.1 * NArray.sfloat( 11 ).indgen
  DCL.gropn( 2 ) # 1: display, 2: pdf
    DCL.glpset( 'lmiss', true )
    #DCL.sgpset( 'lfull', true )

    #GGraph.tone( tvar.cut( "lon" => 141.5..142.5, "lat" => 38.75..39.75 ) ) 
    #GGraph.tone( tvar.cut( "lon" => gxmin..gxmax, "lat" => gymin..gymax ) ) 
    gregion = {"lon" => gxmin..gxmax, "lat" => gymin..gymax}
  vname.each do | vn |
    tvar = GPhys::IO.open( tide_nf, vn )
    GGraph.tone( tvar.cut( gregion ), true, "levels" => clevs ) 
    GGraph.contour( dvar.cut( gregion ), false )
    GGraph.color_bar
  end

  DCL.grcls



