use <pieslice.scad>

$fs=0.1;
$fn=200;

epsilon=0.05;

/// the female/outer part of a Jobo 2502 shaft connection
/// datum is tooth centre, bottom face is at -1.25.
module jobo_female(height=15, slotdepth=11) {

	// stress-relief notches surrounding tooth (outer cyl)
	relief=[4, slotdepth];
	
	// outer cylinder diameters
	diam=[30.5, 36];
	R=0.5*diam;
	thickness=R[1]-R[0];
	middle=0.5*(R[0]+R[1]);
	// angle between notches per pair
	notchsep=40;
	// notch angles
	// notches=[0, 120, 240, notchsep, 120+notchsep, 240+notchsep];
	notches=[0+0.5*notchsep, 120+0.5*notchsep, 240+0.5*notchsep, -0.5*notchsep, 120-0.5*notchsep, 240-0.5*notchsep];
	// tooth angles
	// teeth=[0.5*notchsep, 120+0.5*notchsep, 240+0.5*notchsep];
	teeth=[0, 120, 240];
	// tooth size for locking; goes on inside of outer cylinder
	tooth=[1.5, 3.5, 2.5];
    toothwidth=[3.5, 2.5, 2.5];

    marker=[1.8, 1.5];

	translate([0, 0, -0.5*tooth[2]]){

		difference() {
			// main body
			translate([0, 0, height/2]) cylinder(h=height, r1=R[1], r2=R[1], center=true);

			// subtract inner cylinder
			translate([0, 0, height/2]) cylinder(h=height+epsilon, r1=R[0], r2=R[0], center=true);

			// subtract stress-relief notches
			for(a=notches){
				rotate([0, 0, a]){
					translate([middle, 0, relief[1]/2-0.5])
						cube([thickness+1, relief[0], relief[1]+1], center=true);
					translate([middle, 0, relief[1]])
						rotate([0, 90, 0])
                        cylinder(h=thickness+1, r=0.5*relief[0], center=true, $fn=36);
				}
			}

            // subtract marker-circle
            translate([R[1], 0, 2*marker[0]]) rotate([0, 90, 0]) 
                cylinder(h=marker[1], r=marker[0], center=true, $fn=20);
		}

        // add teeth to bottom edge
		for(i=[0:2]){
			rotate([0, 0, teeth[i]]){
				translate([R[0], 0, 0.5*tooth[2]+epsilon])
					cube([2*tooth[0], toothwidth[i], tooth[2]], center=true);
			}
		}
	}

}

/// the male/inner part of a Jobo 2502 shaft connection, one slot only
/// datum is at zero, in order to mesh with female.  Top surface at Z=4.
module jobo_male(height=10, limitdepth=true, tightretain=false) {
	// inner cylinder diameters
	diam=[25.5, 29.5];
	R=0.5*diam;
    middle=0.5*(R[0]+R[1]);
    thickness=R[1]-R[0];
	
	// z values
    taper=1.5;
	ztop=4;
	ztaper=ztop-taper;
	ztopnotch=1.55;
	zbotnotch=-1.55;
    znotchwidth=ztopnotch-zbotnotch;
    znotchmid=0.5*(ztopnotch+zbotnotch);
    znotchlen=6.5;
    zcentre=ztop-0.5*(height);
    zover=height+epsilon;

    // notch spacing & sizing
    notches=[0, 120, 240];
    notchwidth=[4, 3, 3];
    notchdepth=1.4;
    notchlength=85;

    // retaining teeth
    retainoff=tightretain ? notchlength-20 : 35;
    retains=[-retainoff:120:240-retainoff];

	difference() {
        union() {
            // main cylinder
            translate([0, 0, ztaper-0.5*height+0.5*taper])
                cylinder(h=height-taper, r1=R[1], r2=R[1], center=true);

            // tapered top
            translate([0, 0, ztaper+0.5*taper])
                cylinder(h=taper, r1=R[1], r2=R[1]-taper, center=true);
        }
        // subtract centre core
		translate([0, 0, ztop-0.5*height]) cylinder(h=height+epsilon, r1=R[0], r2=R[0], center=true);

        // subtract all the notch structures
        intersection() {
            // form a notch sleeve
            difference() {                               
                translate([0, 0, zcentre]) cylinder(h=zover, r=R[1]+epsilon, center=true);
                translate([0, 0, zcentre]) cylinder(h=zover+epsilon, r=R[1]-notchdepth, center=true);

                // also subtract retaining-bumps from the possible sleeve
                for(a=retains){
                    rotate([0, 0, a]) {
                        translate([R[1]-notchdepth, 0, znotchmid])
                            rotate([0, 0, 45]) cube([1.5*notchdepth, 1.5*notchdepth, znotchwidth+1], center=true);
                    }
                }
            }

            // decide which bits of the sleeve to keep, i.e. where slots/notches will be
            union() {
                // for(a=notches){
                for(i=[0:3]){
                    rotate([0, 0, notches[i]]){
                        if(limitdepth){
                            // vertical notch going down as far as top slot
                            translate([middle, 0, zbotnotch+0.5*znotchlen])
                                cube([thickness+epsilon, notchwidth[i], znotchlen], center=true);
                        }
                        else{
                            // full-depth vertical notch
                            translate([middle, 0, zcentre])
                                cube([thickness+epsilon, notchwidth[i], zover], center=true);
                        }

                        // tapers on entry to vertical notch
                        translate([middle, 0, ztop]) rotate([45, 0, 0]) 
                            cube([thickness, 0.707*notchwidth[i]+1.414*taper, 0.707*notchwidth[i]+1.414*taper], center=true);

                        // top slot
                        translate([0, 0, zbotnotch])
                            pie_slice(height=znotchwidth, r=R[1]+3, amax=0, amin=-notchlength, aseg=10);
                    }                    
                }
            }
        }
	}
}

/// a spacer to go between two spiral halves, making them 9mm further apart
/// this allows the loading of 70mm film in a 120/220 spiral.  Note that this
/// connects to the second row on the male spiral, which is 16mm below the first row,
/// which is why we have a 16+9=25mm datum offset between the two interfaces.
module jobo_spacer() {

    expand=24;

    mheight=8.5;
    join_top=expand-1.75;
    join_bot=expand-mheight+4;
    join_mid=0.5*(join_top+join_bot);
    join_len=join_top-join_bot;
    join_R=[14, 16];

    echo(join_len);

    difference() {
        union() {
            // male connector at top, rotated so that once locked in, the spiral's
            // angular relationship is unchanged.
            rotate([0, 0, 75]) translate([0, 0, expand]) 
                jobo_male(height=mheight, tightretain=true);

            // joining ring
            difference() {
                translate([0, 0, join_mid]) cylinder(h=join_len, r=join_R[1], center=true);
                translate([0, 0, join_mid]) cylinder(h=join_len+epsilon, r=join_R[0], center=true);
            }
        }

        // subtract out a chamfer to ease the build and provide more clearance
        translate([0, 0, join_bot-epsilon]) 
            cylinder(h=4, r1=16, r2=10);
    }


    // female connector at bottom
    jobo_female(height=expand-0.5);
}

jobo_spacer();  
