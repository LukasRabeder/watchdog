library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

architecture rtl of watchdog is
    signal clk_i                 : std_logic;
    signal rst_n_i               : std_logic;
    signal ui_in_i               : std_logic_vector(7 downto 0);
    signal uio_i                 : std_logic_vector(7 downto 0);
    signal uo_out_i              : std_logic_vector(7 downto 0);

    -- Handshakes
    signal core_busy             : std_logic := '0';
    signal res_valid             : std_logic := '0';  -- 1-Takt-Puls: Ergebnisse fertig
    signal ol_busy               : std_logic := '0';
    signal start_ol              : std_logic := '0';
    signal eig_core_start        : std_logic := '0';

    -- Daten
    signal alpha, beta           : signed(31 downto 0) := (others=>'0');

    signal invK, K               : signed(31 downto 0) := (others=>'0');

    signal regime                : std_logic_vector(2 downto 0);

    begin
    
    clk_i <= clk;
    rst_n_i <= rst_n;
    ui_in_i <= std_logic_vector(ui_in);
    uio_i <= std_logic_vector(uio);
    uo_out <= std_logic_vector(uo_out_i);
    u_pl : entity work.param_loader
    port map 
    (
        clk            => clk_i,
        rst_n          => rst_n,
        in_pins1       => ui_in_i,
        in_pins2       => uio_i,
        a0             => alpha,
        a1             => beta,
        core_busy      => core_busy,
        start_calc     => eig_core_start
    );

    u_core : entity work.eig_core
    port map
    (
        clk            => clk_i,
        rst_n          => rst_n_i,
        data_rdy       => '1',
        a0             => alpha,
        a1             => beta,
        core_busy      => core_busy,
        --omega          => omega,
        kappa          => K,
        --neg_beta_h     => neg_h_b,
        --sqrt_disc_half => sq_h_disc,
        inv_kappa      => invK,
        regime         => regime
    );
    u_ol : entity work.output_loader
    port map (
        clk            => clk_i,
        rst_n          => rst_n_i,
        start          => start_ol,
        mode           => regime,
        wordA          => std_logic_vector(K),
        wordB          => std_logic_vector(invK),
        busy           => ol_busy,
        out_byte       => uo_out_i
    );
end architecture rtl;
