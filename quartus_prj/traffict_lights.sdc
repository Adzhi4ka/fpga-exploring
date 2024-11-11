set_time_format -unit ns -decimal_places 3

create_clock -name {clk_002} -period 2KHz [get_ports {clk_0m002}]

derive_clock_uncertainty