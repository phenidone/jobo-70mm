
/// a partial (in angle) cylinder.  Outside edge is not clean.
/// used for masking off segments of a circular extrusion.
module pie_slice(height, r, amin=0, amax=90, aseg=5, center=false){
    for(a=[amin:aseg:amax-aseg]){

        linear_extrude(height=height, convexity=10, center=center)
            polygon(points=[ [0, 0], 
                             [r*cos((a == amin) ? a : (a-0.05*aseg)), r*sin((a == amin) ? a : (a-0.05*aseg))], 
                             [r*cos(a+aseg), r*sin(a+aseg)] ],
                    paths=[ [0, 1, 2] ]);
    }
}
