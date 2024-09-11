Added a hint to the `Health and Speed Adder` plugin, and a speed limit.

### Cvars

- health_speed_adder_ffa <1/0> - Enable to the plugin works with ffa mod
- health_add_enable <1/0> - Enable or Disable the health bonus by kill
-x health_add <10> - Amount of life added by kill.
-x speed_default <260> - Start speed of a player in the spawn, default value is 260.
-x speed_add_enable <1/0> - Active speed bonus when kill.
-x speed_add <100> - Amount of speed added by kill. (The normal speed of a player is 260).
-x health_limit <100> - Limit of health. 0 to disable.
-x health_speed_msg <1/0> - Enable the menssages when kill a player.
-x health_headshot_add <20> - Extra health added by HeadShot Kill.
-x health_knife_add <50> - Extra health added by Knife Kill.
-x speed_headshot_add <50> - Extra Speed added by HeadShot Kill.
-x speed_knife_add <100> - Extra Speed added by Knife Kill.

### New Cvars

- speed_limit <800> - Max amount of speed after killing.
- speed_hint_enable <1> - Show a hint with the speed.
- hint_tick <0.2> - This sets how often the display is redrawn (this is the display tick rate).
- speed_unit <0> - Unit of measurement of speed (0=kilometers per hour, 1=miles per hour, 2=units per second, 3=meters per second).