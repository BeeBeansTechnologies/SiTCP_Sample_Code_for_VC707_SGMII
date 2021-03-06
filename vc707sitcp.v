

module vc707sitcp (
	input	wire			CLK_P			,
	input	wire			CLK_N			,
	input	wire			SGMII_CLK_P		,
	input	wire			SGMII_CLK_N		,
	output	wire			PHY_RSTn		,	// out	: SiTCP reset
	output	wire			SGMII_TXP		,	// out	: Tx signal line
	output	wire			SGMII_TXN		,	// out	: 
	input	wire			SGMII_RXP		,	// in	: Rx signal line
	input	wire			SGMII_RXN		,	// in	: 
	// Management IF
	output	wire			GMII_MDC		,	// out	: Clock for MDIO
	inout	wire			GMII_MDIO_IN	,
	// reset switch
	input	wire			SW_N			,
	// connect EEPROM
	inout	wire			I2C_SDA			,
	output	wire			I2C_SCL			,

	input	wire	[3:0]	DIP				,
	output	wire	[7:0]	LED
);

	wire			CLK_200M;
	reg				SYS_RSTn;
	reg		[29:0]	INICNT;
	wire			GMII_CLK;		
	wire			GMII_TX_EN;		// out: Tx enable
	wire	[7:0]	GMII_TXD;		// out: Tx data[7:0]
	wire			GMII_TX_ER;		// out: TX error
	wire			GMII_RX_DV;		// in : Rx data valid
	wire	[7:0]	GMII_RXD;		// in : Rx data[7:0]
	wire			GMII_RX_ER;		// in : Rx error
	wire			SiTCP_RST;		// out: Reset for SiTCP and related circuits
	wire			TCP_CLOSE_REQ;	// out: Connection close request
	wire	[15:0]	STATUS_VECTOR;	// out: Core status.[15:0]	
	wire 	[7:0]	TCP_RX_DATA;
	wire 	[7:0]	TCP_TX_DATA;
	wire 			TCP_RX_WR;
	wire 			TCP_TX_FULL;
	wire			TCP_OPEN_ACK;
	wire	[11:0]	FIFO_DATA_COUNT;
	wire			FIFO_RD_VALID;
	wire 	[31:0]	RBCP_ADDR;
	wire 	[7:0]	RBCP_WD;
	wire	[7:0]	RBCP_RD;
	wire			RBCP_ACK;

	wire			Duplex_mode;
	wire	[ 1:0]	LED_LINKSpeed;
	wire			Link_Status;
	wire			userclk;
	wire			userclk2;
	wire			sgmii_clk_en;
	reg		[ 1:0]	SGMII_LINK;
	reg				SEL_SGMII;
	wire	[15:0]	CFG_REG;
	reg				IIC_REQ;
	wire			IIC_ACK;
	wire	[7:0]	IIC_RDT;
	wire			IIC_RVL;
	wire			PHY_RSTn;


	IBUFDS	pre_clk_ibuf(.O(CLK_200M),.I(CLK_P),.IB(CLK_N));


	always@(posedge CLK_200M)begin
		if (SW_N) begin
			INICNT[29:0]	<=	30'd0;
			SYS_RSTn		<=	1'b0;
		end else begin
			INICNT[29:0]		<=	INICNT[29]? INICNT[29:0]:	(INICNT[29:0] + 30'd1);
			SYS_RSTn			<=	INICNT[29];
		end
	end
	
	assign	Link_Status			= STATUS_VECTOR[15];
	assign	Duplex_mode			= STATUS_VECTOR[12];
	assign	LED_LINKSpeed[1:0]	= STATUS_VECTOR[11:10];

	assign		LED[7]		=	~SYS_RSTn;
	assign		LED[6]		=	 1'b0;
	assign		LED[5:2]	=	{LED_LINKSpeed[1:0], Link_Status, Duplex_mode};
	assign		LED[1]		=	 1'b0;
	assign		LED[0]		=	 SiTCP_RESET;
	


	AT93C46_IIC #(
		.PCA9548_AD			(7'b1110_100),				// PCA9548 Dvice Address
		.PCA9548_SL			(8'b0001_1000),				// PCA9548 Select code (Ch3,Ch4 enable)
		.IIC_MEM_AD			(7'b1010_100),				// IIC Memory Dvice Address
		.FREQUENCY			(8'd200),					// CLK_IN Frequency  > 10MHz
		.DRIVE				(4),						// Output Buffer Strength
		.IOSTANDARD			("LVCMOS18"),				// I/O Standard
		.SLEW				("SLOW")					// Outputbufer Slew rate
	)
	AT93C46_IIC	(
		.CLK_IN				(CLK_200M),					// System Clock
		.RESET_IN			(~SYS_RSTn),				// Reset
		.IIC_INIT_OUT		(SiTCP_RESET),				// IIC , AT93C46 Initialize (0=Initialize End)
		.EEPROM_CS_IN		(EEPROM_CS),				// AT93C46 Chip select
		.EEPROM_SK_IN		(EEPROM_SK),				// AT93C46 Serial data clock
		.EEPROM_DI_IN		(EEPROM_DI),				// AT93C46 Serial write data (Master to Memory)
		.EEPROM_DO_OUT		(EEPROM_DO),				// AT93C46 Serial read data(Slave to Master)
		.INIT_ERR_OUT		(),							// PCA9548 Initialize Error
		.IIC_REQ_IN			(IIC_REQ),					// IIC Request
		.IIC_NUM_IN			(8'd0),						// IIC Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC_DAD_IN			(7'b101_0000),				// IIC Device Address[6:0]
		.IIC_ADR_IN			(8'b0000_0110),				// IIC Word Address[7:0]
		.IIC_RNW_IN			(1'b1),						// IIC Read(1) / Write(0)
		.IIC_WDT_IN			(8'd0),						// IIC Write Data[7:0]
		.IIC_RAK_OUT		(IIC_ACK),					// IIC Request Acknowledge
		.IIC_WDA_OUT		(),							// IIC Wite Data Acknowledge(Next Data Request)
		.IIC_WAE_OUT		(),							// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC_BSY_OUT		(),							// IIC Busy
		.IIC_RDT_OUT		(IIC_RDT[7:0]),				// IIC Read Data[7:0]
		.IIC_RVL_OUT		(IIC_RVL),					// IIC Read Data Valid
		.IIC_EOR_OUT		(),							// IIC End of Read Data(same as IIC_RVL timing)
		.IIC_ERR_OUT		(),							// IIC Error Detect
		// Device Interface
		.IIC_SCL_OUT		(I2C_SCL),					// IIC Clock
		.IIC_SDA_IO			(I2C_SDA)					// IIC Data
	);
	
	assign GMII_MDIO_IN		= GMII_MDIO_OE	? GMII_MDIO_OUT : 1'bz;


	WRAP_SiTCP_GMII_XC7V_32K	#(.TIM_PERIOD(8'd200))	SiTCP(
		.CLK				(CLK_200M   		),	// in	: System Clock >129MHz
		.RST				(SiTCP_RESET		),	// in	: System reset
	// Configuration parameters
		.FORCE_DEFAULTn		(DIP[0]	 		 	),	// in	: Load default parameters
		.EXT_IP_ADDR		(32'd0				),	// in	: IP address[31:0]
		.EXT_TCP_PORT		(16'd0				),	// in	: TCP port #[15:0]
		.EXT_RBCP_PORT		(16'd0				),	// in	: RBCP port #[15:0]
		.PHY_ADDR			(5'd0				),	// in	: PHY-device MIF address[4:0]
	// EEPROM
		.EEPROM_CS			(EEPROM_CS			),	// out	: Chip select
		.EEPROM_SK			(EEPROM_SK			),	// out	: Serial data clock
		.EEPROM_DI			(EEPROM_DI			),	// out	: Serial write data
		.EEPROM_DO			(EEPROM_DO			),	// in	: Serial read data
		// user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
		.USR_REG_X3C		(					),	// out	: Stored at 0xFFFF_FF3C
		.USR_REG_X3D		(					),	// out	: Stored at 0xFFFF_FF3D
		.USR_REG_X3E		(					),	// out	: Stored at 0xFFFF_FF3E
		.USR_REG_X3F		(					),	// out	: Stored at 0xFFFF_FF3F
	// MII interface
		.GMII_RSTn			(PHY_RSTn			),	// out	: PHY reset Active low
		.GMII_1000M			(1'b1				),	// in	: GMII mode (0:MII, 1:GMII)
		// TX
		.GMII_TX_CLK		(GMII_CLK			),	// in	: Tx clock
		.GMII_TX_EN			(GMII_TX_EN			),	// out	: Tx enable
		.GMII_TXD			(GMII_TXD[7:0]		),	// out	: Tx data[7:0]
		.GMII_TX_ER			(GMII_TX_ER			),	// out	: TX error
		// RX
		.GMII_RX_CLK		(GMII_CLK			),	// in	: Rx clock
		.GMII_RX_DV			(GMII_RX_DV			),	// in	: Rx data valid
		.GMII_RXD			(GMII_RXD[7:0]		),	// in	: Rx data[7:0]
		.GMII_RX_ER			(GMII_RX_ER			),	// in	: Rx error
		.GMII_CRS			(1'b0				),	// in	: Carrier sense
		.GMII_COL			(1'b0				),	// in	: Collision detected
		// Management IF
		.GMII_MDC			(GMII_MDC			),	// out	: Clock for MDIO
		.GMII_MDIO_IN		(GMII_MDIO_IN		),	// in	: Data
		.GMII_MDIO_OUT		(GMII_MDIO_OUT		),	// out	: Data
		.GMII_MDIO_OE		(GMII_MDIO_OE		),	// out	: MDIO output enable
	// User I/F
		.SiTCP_RST			(SiTCP_RST			),	// out	: Reset for SiTCP and related circuits
		// TCP connection control
		.TCP_OPEN_REQ		(1'b0				),	// in	: Reserved input, shoud be 0
		.TCP_OPEN_ACK		(TCP_OPEN_ACK		),	// out	: Acknowledge for open (=Socket busy)
		.TCP_ERROR			(					),	// out	: TCP error, its active period is equal to MSL
		.TCP_CLOSE_REQ		(TCP_CLOSE_REQ		),	// out	: Connection close request
		.TCP_CLOSE_ACK		(TCP_CLOSE_REQ		),	// in	: Acknowledge for closing
		// FIFO I/F
		.TCP_RX_WC			({4'b1111,FIFO_DATA_COUNT[11:0]}),	// in	: Rx FIFO write count[15:0] (Unused bits should be set 1)
		.TCP_RX_WR			(TCP_RX_WR			),	// out	: Write enable
		.TCP_RX_DATA		(TCP_RX_DATA[7:0]	),	// out	: Write data[7:0]
		.TCP_TX_FULL		(TCP_TX_FULL		),	// out	: Almost full flag
		.TCP_TX_WR			(FIFO_RD_VALID		),	// in	: Write enable
		.TCP_TX_DATA		(TCP_TX_DATA[7:0]	),	// in	: Write data[7:0]
		// RBCP
		.RBCP_ACT			(					),	// out	: RBCP active
		.RBCP_ADDR			(RBCP_ADDR[31:0]	),	// out	: Address[31:0]
		.RBCP_WD			(RBCP_WD[7:0]		),	// out	: Data[7:0]
		.RBCP_WE			(RBCP_WE			),	// out	: Write enable
		.RBCP_RE			(RBCP_RE			),	// out	: Read enable
		.RBCP_ACK			(RBCP_ACK			),	// in	: Access acknowledge
		.RBCP_RD			(RBCP_RD[7:0]		)	// in	: Read data[7:0]
	);	


	WRAP_gig_ethernet_pcs_pma_0 gig_ethernet_pcs_pma_0 (
		.SYS_CLK			(CLK_200M			),
		.RESET_IN			(~SYS_RSTn			),
		
		.SGMII_CLK_P		(SGMII_CLK_P		),
		.SGMII_CLK_N		(SGMII_CLK_N		),
		.SGMII_TXP			(SGMII_TXP			),	// out	: Tx signal line
		.SGMII_TXN			(SGMII_TXN			),	// out	: 
		.SGMII_RXP			(SGMII_RXP			),	// in	: Rx signal line
		.SGMII_RXN			(SGMII_RXN			),	// in	: 

		.GMII_CLK			(GMII_CLK			),	// out : GMII Shared clock
		.GMII_TX_EN			(GMII_TX_EN			),	// in : Tx enable
		.GMII_TXD			(GMII_TXD[7:0]		),	// in : Tx data[7:0]
		.GMII_TX_ER			(GMII_TX_ER			),	// in : TX error
		.GMII_RX_DV			(GMII_RX_DV			),	// out : Rx data valid
		.GMII_RXD			(GMII_RXD[7:0]		),	// out : Rx data[7:0]
		.GMII_RX_ER			(GMII_RX_ER			),	// out : Rx error
	
		.STATUS_VECTOR		(STATUS_VECTOR[15:0])
	);



	fifo_generator_v11_0 fifo_generator_v11_0(
		.clk				(CLK_200M			),	//in	:
		.rst				(~TCP_OPEN_ACK		),	//in	:
		.din				(TCP_RX_DATA[7:0]	),	//in	:
		.wr_en				(TCP_RX_WR			),	//in	:
		.full				(					),	//out	:
		.dout				(TCP_TX_DATA[7:0]	),	//out	:
		.valid				(FIFO_RD_VALID		),	//out	:active h
		.rd_en				(~TCP_TX_FULL		),	//in	:
		.empty				(					),	//out	:
		.data_count			(FIFO_DATA_COUNT[11:0])	//out	:
	);
	RBCP	RBCP(
		.CLK_200M			(CLK_200M),	//in
		.DIP				(DIP[3:1]			),	//in
		.RBCP_WE			(RBCP_WE			),	//in
		.RBCP_RE			(RBCP_RE			),	//in
		.RBCP_WD			(RBCP_WD			),	//in
		.RBCP_ADDR			(RBCP_ADDR			),//in
		.RBCP_RD			(RBCP_RD			),	//out
		.RBCP_ACK			(RBCP_ACK			)	//out
	
	);

endmodule

