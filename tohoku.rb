

# load libraries
require "numru/gphys"
include NumRu
require "~/lib_k247/K247_basic"

# 2016-09-03: create
#   tide speed vs depth ( jegg500 )


# Main 4 component tides
  #tide_type = "m2" # M2: moon semi-diurnal
  #tide_type = "s2" # S2: sun semi-diurnal
  #tide_type = "k1" # K1: mixed diurnal
  #tide_type = "o1" # O1: moon diurnal

 # main 8
  #tide_type = "p1" # : diurnal
  #tide_type = "n2" # : diurnal
  #tide_type = "k2" # : diurnal
  #tide_type = "mf" # : 14day ( not included in nao99Jb)
  
 # main 16
  tide_type = "q1" # : diurnal
  #tide_type = "m1" # : diurnal
  #tide_type = "j1" # : diurnal
  #tide_type = "oo1" # : diurnal
  #tide_type = "2n2" # : diurnal
  #tide_type = "mu2" # : diurnal
  #tide_type = "nu2" # : diurnal
  #tide_type = "l2" # : diurnal
  #tide_type = "t2" # : diurnal

  dname   = "nao99Jb_vel"
    xmin  = 141.0; xmax = 144.0
    ymin  =  38.0; ymax =  40.0
    rname = "#{xmin.to_i}to#{xmax.to_i}E_#{ymin.to_i}to#{ymax.to_i}N"
  tide_nf = "#{dname}/cut_#{tide_type}_#{rname}.nc"
  puts "tide_nf : #{tide_nf}"
  #vnames = "spd" # "au", "av", "spd", "pu", "pv"
  #vnames = [ "au", "av", "spd" ]
  vnames = [ "au", "av", "spd", "pu", "pv" ]
    velnames = [ "au", "av", "spd" ]
    phnames  = [ "pu", "pv" ]
  

# depth
  dep_nf = "#{dname}/jegg500_#{rname}.nc"
  # from jegg_k247
  puts "dep_nf  : #{dep_nf}"
  vdep = "depth"
  dvar = GPhys::IO.open( dep_nf, vdep )
  

# 
  gxmin = 141.5; gxmax = 142.5; gymin = 38.75; gymax = 39.75
  #gxmin = 141.0; gxmax = 144.0; gymin =  38.0; gymax =  40.0
  velevs = 0.5 * NArray.sfloat( 11 ).indgen
  #velevs = 0.1 * NArray.sfloat( 11 ).indgen + 1.0
  #velevs = 0.1 * NArray.sfloat( 11 ).indgen + 0.5
  #velevs = 0.1 * NArray.sfloat( 11 ).indgen
  #phlevs = 10 * NArray.sfloat( 36 ).indgen
  phlevs = 20 * NArray.sfloat( 19 ).indgen
  out_type = 2  # 1: display, 2: pdf
  DCL.gropn( out_type ) # 1: display, 2: pdf
    DCL.glpset( 'lmiss', true )
    #DCL.sgpset( 'lfull', true )

    #GGraph.tone( tvar.cut( "lon" => 141.5..142.5, "lat" => 38.75..39.75 ) ) 
    #GGraph.tone( tvar.cut( "lon" => gxmin..gxmax, "lat" => gymin..gymax ) ) 
    gregion = {"lon" => gxmin..gxmax, "lat" => gymin..gymax}
  vnames.each do | vn |
    tvar = GPhys::IO.open( tide_nf, vn )
    gttl = tide_type.upcase + ": " + tvar.long_name
    if velnames.include?( vn )
      clevs = velevs
    else
      clevs = phlevs
    end
    GGraph.tone( tvar.cut( gregion ), true, "levels" => clevs, \
                "title" => gttl ) 
    GGraph.contour( dvar.cut( gregion ), false )
    GGraph.color_bar
  end

  DCL.grcls

  # 2016-10-11
  if out_type == 2
    cmd_rotate =  "pdftk dcl.pdf cat 1-endright output #{tide_type}_tohoku.pdf" 
    puts(   cmd_rotate )
    system( cmd_rotate )
  end



