
marker = {}

-- can store two positions for each player
marker.positions = {}


marker.marker_placed = function( pos, placer, itemstack )
 
   if( not( pos ) or not( placer )) then
      return;
   end
 
   local meta = minetest.env:get_meta( pos );
   local name = placer:get_player_name();

   meta:set_string( 'infotext', 'Marker at '..minetest.pos_to_string( pos )..' (placed by '..tostring( name )..'). Right-click to update.');
   meta:set_string( 'owner',    name );

   local txt = '';

   if( not( marker.positions[ name ] )) then
      marker.positions[ name ] = {};
      marker.positions[ name ][ 1 ] = pos;
      marker.positions[ name ][ 2 ] = pos; -- make sure the table has always two entries
      marker.positions[ name ][ 3 ] = 1;   -- one marker set
 
      minetest.chat_send_player( name, 'First marker set to position '..minetest.pos_to_string( marker.positions[ name ][ 1 ] )..
                                       '. Please place a second marker to define an area.');
   else
      -- remove the node at the old position if possible; if not, it will just sit there until someone digs it

      -- if two nodes have been set already, remove the old one if possible
      if(  marker.positions[ name ][ 3 ] > 1 ) then

         local old_node = minetest.env:get_node( marker.positions[ name ][ 1 ] );
         -- is that node loaded and does it contain a marker? If so, remove the old one
         if( old_node and old_node.name ~= 'ignore' and old_node.name == 'marker:marker' ) then
            -- actually remove the old marker
            minetest.env:set_node( marker.positions[ name ][ 1 ], {name='air'} );
            -- return the old marker to the players inventory
            placer:get_inventory():add_item("main", "marker:marker 1");
            minetest.chat_send_player( name, 'Removing now obsolete old marker at '..minetest.pos_to_string( marker.positions[ name ][ 1 ] )..'.');
         else
            minetest.chat_send_player( name, 'Warning: Your old marker at '..minetest.pos_to_string( marker.positions[ name ][ 1 ] )..
                     ' is now obsolete. It could not be removed automaticly. Please do so manually!');
         end
      end

      marker.positions[ name ][ 1 ] = marker.positions[ name ][ 2 ];
      marker.positions[ name ][ 2 ] = pos;
      marker.positions[ name ][ 3 ] = 2;   -- both markers set
   end

   local area   =        (math.abs( marker.positions[ name ][ 1 ].x - marker.positions[ name ][ 2 ].x )+1)
                       * (math.abs( marker.positions[ name ][ 1 ].z - marker.positions[ name ][ 2 ].z )+1);
   local volume = area * (math.abs( marker.positions[ name ][ 1 ].y - marker.positions[ name ][ 2 ].y )+1);

   minetest.chat_send_player( name, 'Markers set to '..minetest.pos_to_string( marker.positions[ name ][ 1 ] )..' and '..
                                                                minetest.pos_to_string( marker.positions[ name ][ 2 ] )..'. Distance: '..
                                     ' x: '..tostring( math.abs(marker.positions[ name ][ 2 ].x - marker.positions[ name ][ 1 ].x))..
                                    ', y: '..tostring( math.abs(marker.positions[ name ][ 2 ].y - marker.positions[ name ][ 1 ].y))..
                                    ', z: '..tostring( math.abs(marker.positions[ name ][ 2 ].z - marker.positions[ name ][ 1 ].z))..
                                    '. Area covered: '..tostring( area )..' m^2. Volume covered: '..tostring( volume )..' m^3.');

end



marker.marker_dig = function(pos,player) 

   if( not( pos ) or not( player )) then
      return true;
   end

   local meta  = minetest.env:get_meta( pos );
   local owner = meta:get_string( 'owner' );
   -- can the marker be removed?
   if( not( owner ) 
       or owner=='' 
       or not( marker.positions[ owner ] )
       or (       owner == player:get_player_name()
          and  ( marker.positions[ owner ][ 1 ].x ~= pos.x 
              or marker.positions[ owner ][ 1 ].y ~= pos.y 
              or marker.positions[ owner ][ 1 ].z ~= pos.z )
          and  ( marker.positions[ owner ][ 2 ].x ~= pos.x 
              or marker.positions[ owner ][ 2 ].y ~= pos.y 
              or marker.positions[ owner ][ 2 ].z ~= pos.z ))) then

      minetest.chat_send_player( player:get_player_name(), 'Thank you for cleaning up this leftover marker!');
      return true;

   -- marker owned by someone else and still in use
   elseif( owner ~= player:get_player_name() ) then

      minetest.chat_send_player( player:get_player_name(), 'Sorry, this marker is still in use by '..tostring( owner )..'.');
      return false;

   -- the marker marked pos1
   elseif (      marker.positions[ owner ][ 1 ].x == pos.x 
             and marker.positions[ owner ][ 1 ].y == pos.y 
             and marker.positions[ owner ][ 1 ].z == pos.z ) then

      
      -- if this was already the last marker
      if( marker.positions[ owner ][ 3 ] == 1 ) then
         marker.positions[ owner ] = nil;
         minetest.chat_send_player( owner, 'Removed your last marker.');
      else
         marker.positions[ owner ][ 1 ] = marker.positions[ owner ][ 2 ];
         marker.positions[ owner ][ 3 ] = 1;   -- only one marker left
         minetest.chat_send_player( owner, 'Your remaining marker is at '..minetest.pos_to_string( marker.positions[ owner ][ 1 ] )..'.');
     end
     return true;
   
   -- the marker marked pos2
   elseif (      marker.positions[ owner ][ 2 ].x == pos.x 
             and marker.positions[ owner ][ 2 ].y == pos.y 
             and marker.positions[ owner ][ 2 ].z == pos.z ) then

      
      -- if this was already the last marker
      if( marker.positions[ owner ][ 3 ] == 1 ) then
         marker.positions[ owner ] = nil;
         minetest.chat_send_player( 'Removed your last marker.');
      else
         marker.positions[ owner ][ 2 ] = marker.positions[ owner ][ 1 ];
         marker.positions[ owner ][ 3 ] = 1;   -- only one marker left
         minetest.chat_send_player( owner, 'Your remaining marker is at '..minetest.pos_to_string( marker.positions[ owner ][ 1 ] )..'.');
     end
     return true;

   end
end


minetest.register_node("marker:marker", {
	description = "Marker",
	tiles = {"marker_marker.png"},
	groups = {snappy=2,choppy=2,dig_immediate=3},
	light_source = 15,

        after_place_node = function(pos, placer, itemstack)
           marker.marker_placed( pos, placer, itemstack );
        end,
  
        -- the node is digged immediately, so we may as well do all the work in can_dig (any wrong digs are not that critical)
        can_dig = function(pos,player) 
           return marker.marker_dig( pos, player );
        end
})

