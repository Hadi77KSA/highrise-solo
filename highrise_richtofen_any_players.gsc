#include maps\mp\zm_highrise_sq;
#include maps\mp\zombies\_zm_sidequests;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zm_highrise_sq_pts;
#include maps\mp\zm_highrise_sq_atd;

init()
{
    replacefunc( ::sq_atd_elevators, ::custom_sq_atd_elevators );
    replacefunc( ::sq_atd_drg_puzzle, ::custom_sq_atd_drg_puzzle );
    replacefunc( ::drg_puzzle_trig_think, ::custom_drg_puzzle_trig_think );
    replacefunc( ::wait_for_all_springpads_placed, ::custom_wait_for_all_springpads_placed );
    replacefunc( ::springpad_count_watcher, ::custom_springpad_count_watcher );
}

custom_sq_atd_elevators()
{
    a_elevators = array( "elevator_bldg1b_trigger", "elevator_bldg1d_trigger", "elevator_bldg3b_trigger", "elevator_bldg3c_trigger" );
    a_elevator_flags = array( "sq_atd_elevator0", "sq_atd_elevator1", "sq_atd_elevator2", "sq_atd_elevator3" );

    for ( i = 0; i < a_elevators.size; i++ )
    {
        trig_elevator = getent( a_elevators[i], "targetname" );
        trig_elevator thread sq_atd_watch_elevator( a_elevator_flags[i] );
    }

    while ( !standing_on_enough_elevators_check( a_elevator_flags ) )
    {
        flag_wait_any_array( a_elevator_flags );
        wait 0.5;
    }
    a_dragon_icons = getentarray( "elevator_dragon_icon", "targetname" );

    foreach ( m_icon in a_dragon_icons )
    {
        v_off_pos = m_icon.m_lit_icon.origin;
        m_icon.m_lit_icon unlink();
        m_icon unlink();
        m_icon.m_lit_icon.origin = m_icon.origin;
        m_icon.origin = v_off_pos;
        m_icon.m_lit_icon linkto( m_icon.m_elevator );
        m_icon linkto( m_icon.m_elevator );
        m_icon playsound( "zmb_sq_symbol_light" );
    }

    flag_set( "sq_atd_elevator_activated" );
    vo_richtofen_atd_elevators();
    level thread vo_maxis_atd_elevators();
}

standing_on_enough_elevators_check( a_elevator_flags )
{
    n_players_standing_on_elevator = 0;

    foreach( m_elevator_flag in a_elevator_flags )
    {
        if( flag( m_elevator_flag ) )
        {
            n_players_standing_on_elevator++;
        }
    }

    return n_players_standing_on_elevator >= custom_get_number_of_players();
}

custom_sq_atd_drg_puzzle()
{
    level.sq_atd_cur_drg = 4 - custom_get_number_of_players();
    a_puzzle_trigs = getentarray( "trig_atd_drg_puzzle", "targetname" );
    a_puzzle_trigs = array_randomize( a_puzzle_trigs );

    for ( i = 0; i < a_puzzle_trigs.size; i++ )
        a_puzzle_trigs[i] thread drg_puzzle_trig_think( i );

    while ( level.sq_atd_cur_drg < 4 )
        wait 1;

    flag_set( "sq_atd_drg_puzzle_complete" );
    level thread vo_maxis_atd_order_complete();
}

custom_drg_puzzle_trig_think( n_order_id )
{
    self.drg_active = 0;
    m_unlit = getent( self.target, "targetname" );
    m_lit = m_unlit.lit_icon;
    v_top = m_unlit.origin;
    v_hidden = m_lit.origin;

    while ( !flag( "sq_atd_drg_puzzle_complete" ) )
    {
        if ( self.drg_active )
        {
            level waittill_either( "sq_atd_drg_puzzle_complete", "drg_puzzle_reset" );

            if ( flag( "sq_atd_drg_puzzle_complete" ) )
                continue;
        }

        self waittill( "trigger", e_who );

        if ( level.sq_atd_cur_drg == n_order_id )
        {
            m_lit.origin = v_top;
            m_unlit.origin = v_hidden;
            m_lit playsound( "zmb_sq_symbol_light" );
            self.drg_active = 1;
            level thread vo_richtofen_atd_order( level.sq_atd_cur_drg );
            level.sq_atd_cur_drg++;
            self thread drg_puzzle_trig_watch_fade( m_lit, m_unlit, v_top, v_hidden );
        }
        else
        {
            if ( !flag( "sq_atd_drg_puzzle_1st_error" ) )
                level thread vo_maxis_atd_order_error();

            level.sq_atd_cur_drg = 4 - custom_get_number_of_players();
            level notify( "drg_puzzle_reset" );
            wait 0.5;
        }

        while ( e_who istouching( self ) )
            wait 0.5;
    }
}

custom_wait_for_all_springpads_placed( str_type, str_flag )
{
    a_spots = getstructarray( str_type, "targetname" );

    while ( !flag( str_flag ) )
    {
        is_clear = 0;

        foreach ( s_spot in a_spots )
        {
            if ( !isdefined( s_spot.springpad ) )
                is_clear++;
        }

        if ( !( is_clear > ( 4 - custom_get_number_of_players() ) ) )
            flag_set( str_flag );

        wait 1;
    }
}

custom_springpad_count_watcher( is_generator )
{
    level endon( "sq_pts_springad_count4" );
    str_which_spots = "pts_ghoul";

    if ( is_generator )
        str_which_spots = "pts_lion";

    a_spots = getstructarray( str_which_spots, "targetname" );

    while ( true )
    {
        level waittill( "sq_pts_springpad_in_place" );

        n_count = 0;

        foreach ( s_spot in a_spots )
        {
            if ( isdefined( s_spot.springpad ) )
                n_count++;
        }

        level notify( "sq_pts_springad_count" + n_count );
        n_players = custom_get_number_of_players();
        while ( n_count >= n_players && n_count < 4 )
        {
            wait 10;
            n_count++;
            level notify( "sq_pts_springad_count" + n_count );
        }
    }
}

custom_get_number_of_players()
{
    if( getPlayers().size > 4 )
    {
        n_players = 4;
    }
    else
    {
        n_players = getPlayers().size;
    }

    return n_players;
}
