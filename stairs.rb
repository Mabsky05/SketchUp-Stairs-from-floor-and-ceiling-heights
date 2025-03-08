# Create input box
prompts = ["stair height", "minimum riser height", "maximum riser height", "step_length", "width of stairs"]
defaults = [3000, 150, 180, 250, 1000]
input = UI.inputbox(prompts, defaults, "Enter Stair Data")

stair_ht = Float(input[0])
min = Float(input[1])
max = Float(input[2])
step_length = Float(input[3])
width = Float(input[4])

#Restriction clauses
# if min < 150
#   puts "minimum riser height is less than 130"
# end

#Get step heights
#TODO add riser section
def list(stair_ht, min, max, step_length, width)

  #average of two given riser values, ideally based on building code
  avg_riser_ht = (min + max) / 2
  
  #number of steps (round down to integer)
  step_number = (stair_ht / avg_riser_ht).floor
  
  # remainder from rounding down
  rem1 = stair_ht % (avg_riser_ht)
  
  # remainder to be added to each riser except first 
  step_add = rem1 / (step_number - 1)
  
  # first riser height = subtract total 'padded' risers from height 
  riser_init = stair_ht - ((step_number - 1) * (avg_riser_ht + step_add))

  # riser heights for rest of risers 
  riser_rest = avg_riser_ht + step_add
  
  tread = step_length
  width = width

  # List of points to 'trace' stair
  def riser_tread(riser_init, riser_rest, step_number, tread, width)
    steps_list = [ [0, 0, 0], [0, 0, riser_init], [0, tread, riser_init], [0, tread, riser_init + riser_rest]]
    riser_start = riser_init + riser_rest
    tread_start = tread    
        steps = 0
        while steps < ((step_number * 2) -3)
          steps += 1
  
            if steps % 2 == 0
              riser_start = riser_start + riser_rest
              steps_list.append([0, tread_start, riser_start])
    
            else
              tread_start = tread_start + tread
              steps_list.append([0, tread_start, riser_start])
  
            end          
        end

    model = Sketchup.active_model.entities
    
    # Vectors
    move_900z = Geom::Transformation.translation([0 ,0 , 900.mm])
    move_300y = Geom::Transformation.translation([0 ,300.mm , 0])
    move_x_width = Geom::Transformation.translation([-width, 0 , 0])  
     
    # Rail extension points
    move_300y = Geom::Transformation.translation(Geom::Vector3d.new(0, 300.mm, 0))
    move_neg300y = Geom::Transformation.translation(Geom::Vector3d.new(0, -300.mm, 0))
    rail_pt1 = move_neg300y * steps_list[1]
    rail_pt2 = move_300y * steps_list[-3]
    
    # Rail points are rail_extPt1, steps_list[1], steps_list[-3], rail_extPt2
    # Move points on rail up
    rail_pt1z = move_900z * rail_pt1
    steps_list1z = move_900z * steps_list[1]
    steps_list3z = move_900z * steps_list[-3]
    rail_pt2z = move_900z * rail_pt2

    # Move duplicates across to create second rail
    rail_pt1z2 = move_x_width * rail_pt1z
    steps_list1z2 = move_x_width * steps_list1z
    steps_list3z2 = move_x_width * steps_list3z
    rail_pt2z2 = move_x_width * rail_pt2z

    # Create rails
    rail = model.add_curve rail_pt1z, steps_list1z, steps_list3z, rail_pt2z
    rail2 = model.add_curve rail_pt1z2, steps_list1z2, steps_list3z2, rail_pt2z2

    # Draw a circle along rail and extrude  
    rail_circle = model.add_circle rail_pt1z, [0,1,0], 25.mm
    rail_circle_srf = model.add_face (rail_circle)
    rail_pipe = rail_circle_srf.followme rail

    # Draw a circle along 2nd rail and extrude  
    rail_circle2 = model.add_circle rail_pt1z2, [0,1,0], 25.mm
    rail_circle_srf2 = model.add_face (rail_circle2)
    rail_pipe2 = rail_circle_srf2.followme rail2

    # 2 additional points. This is for completing the stair profile
    vector_pt_anchor2 = Geom::Vector3d.new(0, 0, -riser_rest)
    move_pt_anchor2 = Geom::Transformation.translation(vector_pt_anchor2)
    pt_anchor1 =[0, tread, 0]
    pt_anchor2 = move_pt_anchor2 * (steps_list.last)

    # Append 2 additional points, complete stair profile, then extrude by width
    steps_list.prepend(pt_anchor1)
    steps_list.append(pt_anchor2)
    steps_list.append(pt_anchor1)
    stair_face = model.add_face (steps_list)
    stair_face.pushpull(width)

  end

  riser_tread(riser_init, riser_rest, step_number, tread, width)

end


list(stair_ht.mm, min.mm, max.mm, step_length.mm, width.mm)





