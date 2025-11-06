library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

architecture rtl of watchdog is
    signal clk_i       : std_ulogic;
    signal rst_n_i     : std_ulogic;
    signal ui_in_i     : std_ulogic_vector(7 downto 0);
    signal uio_i     : std_ulogic_vector(7 downto 0);
    signal uo_out_i    : std_ulogic_vector(7 downto 0);

    signal handshake_s : std_ulogic := '0';
    signal data      : std_ulogic_vector(15 downto 0) := (others => '0');
    signal data_dummy : std_ulogic_vector(15 downto 0) := (others => '0');
    signal rdy       : std_ulogic  := '0';
    signal busy   : std_ulogic  := '0';

    begin
    
    clk_i <= clk;
    rst_n_i <= rst_n;
    ui_in_i <= ui_in;
    uio_i <= uio;
    uo_out <= uo_out_i;
    
  ---------------------------------------------------------------------------
  -- PARAM_LOADER: liest Eingaben (ui_in/uio) und liefert X + valid
  -- HINWEIS: Passe die Portnamen an deine echte Entity an (param_loader-ea.vhd).
  ---------------------------------------------------------------------------
  u_pl : entity work.param_loader
    port map (
        clk         => clk_i,
        rst_n       => rst_n_i,
        in_data     => ui_in_i,
        in_valid    => '1',  -- Annahme: Immer valide Daten
        in_ready    => rdy,
        a0          => data,
        a1          => data_dummy,
        start_calc  => handshake_s,
        core_busy   => busy
    );

    ---------------------------------------------------------------------------
  -- CORE: rechnet Quadratwurzel aus uin
  -- HANDSHAKE
  ---------------------------------------------------------------------------
    u_core : entity work.isqrt
    port map
    (
        clk         => clk_i,
        rst_n       => rst_n_i,
        start       => handshake_s,
        din         => data,
        dout        => uo_out_i,
        done        => handshake_s
    );
      ---------------------------------------------------------------------------
  -- OUTPUT LOADER: sendet Ergebnis (uo_out) wenn bereit
  ---------------------------------------------------------------------------
    u_ol : entity work.output_loader
    port map (
        clk             => clk_i,
        rst_n           => rst_n_i,
        core_done       => handshake_s,
        lam0_re_in     => data,
        lam0_im_in     => data_dummy,
        lam1_re_in     => data_dummy,
        lam1_im_in     => data_dummy,
        out_ready       => rdy,
        out_data        => uo_out_i,
        out_valid       => '1',
        core_busy_out   => busy
    );
end architecture rtl;
