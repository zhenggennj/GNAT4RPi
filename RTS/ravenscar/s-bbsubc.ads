------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--      S Y S T E M . B B . P E R I P H E R A L S . R E G I S T E R S       --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2006 The European Space Agency            --
--                     Copyright (C) 2003-2011, AdaCore                     --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
-- The porting of GNARL to bare board  targets was initially developed by   --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

--  This package provides the appropriate mapping for the system registers.
--  Rewrite for BCM2835 by L. G. Zheng
pragma Restrictions (No_Elaboration_Code);

with Interfaces;

package System.BB.Board_Support.Bcm2835 is
   pragma Preelaborate;

   subtype Register_32 is Interfaces.Unsigned_32;

   type Bit      is (Clear, Set);
   for  Bit      use (Clear => 0, Set => 1);
   for  Bit'Size use 1;

   --  Interrupt identifiers

   ST_CM0_INT      : constant := 0; --  System Timer
   ST_CM1_INT      : constant := 1;
   ST_CM2_INT      : constant := 2;
   ST_CM3_INT      : constant := 3;
   AUX_INT         : constant := 29;
   I2C_SPI_SLV_INT : constant := 43;
   PWA0_INT        : constant := 45;
   PWA1_INT        : constant := 46;
   SMI_INT         : constant := 48;
   GPIO_INT0       : constant := 49;
   GPIO_INT1       : constant := 50;
   GPIO_INT2       : constant := 51;
   GPIO_INT3       : constant := 52;
   I2C_INT         : constant := 53;
   SPI_INT         : constant := 54;
   PCM_INT         : constant := 55;
   UART_INT        : constant := 57;
   AT_INT          : constant := 64; --  ARM Timer
   REG1_HAS_PENDING    : constant := 72;
   REG2_HAS_PENDING    : constant := 73;
   type IRQ_Reg_3x_Bit_Array is array (0 .. 95) of Bit;
   pragma Pack (IRQ_Reg_3x_Bit_Array);
   pragma Volatile (IRQ_Reg_3x_Bit_Array);
   --   for IRQ_Reg_3x'Alignment use 4;
   for IRQ_Reg_3x_Bit_Array'Size use 96;

   type IRQ_Reg_3x_Bool_Array is array (0 .. 95) of Boolean;
   pragma Pack (IRQ_Reg_3x_Bool_Array);
   pragma Volatile (IRQ_Reg_3x_Bool_Array);
   for IRQ_Reg_3x_Bool_Array'Size use 96;

   --  The 96bit Array represents the Enable_ and Disable_ register sequence
   --  GPU Reg1, GPU Reg2 and Basic Reg.
   --  Interrupt_ID can directly be used to access individual bits.
   --  Exception: for Pending Regs, the register sequence is
   --  Basic Reg, GPU Reg1 and GPU Reg2.
   --  Interrupt_ID must be converted to bit position in the following way:
   --  bit_pos := (Interrupt_ID + 32) mod 96.

   IRQ_Pending : IRQ_Reg_3x_Bool_Array;
   for IRQ_Pending'Address use System'To_Address (16#2000_B200#);

   IRQ_Enable : IRQ_Reg_3x_Bit_Array;
   for IRQ_Enable'Address use System'To_Address (16#2000_B210#);

   IRQ_Disable : IRQ_Reg_3x_Bit_Array;
   for IRQ_Disable'Address use System'To_Address (16#2000_B21C#);

   --  Auxiliary Peripherals Register

   --  Auxiliary Interrupt status Register
   AUX_IRQ : Register_32;
   for AUX_IRQ'Address use System'To_Address (16#2021_5000#);
   pragma Atomic (AUX_IRQ);

   --  Auxiliary enables
   AUX_ENABLES : Register_32;
   for AUX_ENABLES'Address use System'To_Address (16#2021_5004#);
   pragma Atomic (AUX_ENABLES);

   --  Mini Uart (Uart 1)
   --  Mini Uart I/O Data
   AUX_MU_IO_REG : Register_32;
   for AUX_MU_IO_REG'Address use System'To_Address (16#2021_5040#);
   pragma Atomic (AUX_MU_IO_REG);

   --  Mini Uart Interrupt Enable
   AUX_MU_IER_REG : Register_32;
   for AUX_MU_IER_REG'Address use System'To_Address (16#2021_5044#);
   pragma Atomic (AUX_MU_IER_REG);

   --  Mini Uart Interrupt Identity
   AUX_MU_IIR_REG : Register_32;
   for AUX_MU_IIR_REG'Address use System'To_Address (16#2021_5048#);
   pragma Atomic (AUX_MU_IIR_REG);

   --  Mini Uart Line Control
   AUX_MU_LCR_REG : Register_32;
   for AUX_MU_LCR_REG'Address use System'To_Address (16#2021_504C#);
   pragma Atomic (AUX_MU_LCR_REG);

   --  Mini Uart Modem Control
   AUX_MU_MCR_REG : Register_32;
   for AUX_MU_MCR_REG'Address use System'To_Address (16#2021_5050#);
   pragma Atomic (AUX_MU_MCR_REG);

   --  Mini Uart Line Status
   AUX_MU_LSR_REG : Register_32;
   for AUX_MU_LSR_REG'Address use System'To_Address (16#2021_5054#);
   pragma Atomic (AUX_MU_LSR_REG);

   --  Mini Uart Modem Status
   AUX_MU_MSR_REG : Register_32;
   for AUX_MU_MSR_REG'Address use System'To_Address (16#2021_5058#);
   pragma Atomic (AUX_MU_MSR_REG);

   --  Mini Uart Scratch
   AUX_MU_SCRATCH : Register_32;
   for AUX_MU_SCRATCH'Address use System'To_Address (16#2021_505C#);
   pragma Atomic (AUX_MU_SCRATCH);

   --  Mini Uart Extra Control
   AUX_MU_CNTL_REG : Register_32;
   for AUX_MU_CNTL_REG'Address use System'To_Address (16#2021_5060#);
   pragma Atomic (AUX_MU_CNTL_REG);

   --  Mini Uart Extra Status
   AUX_MU_STAT_REG : Register_32;
   for AUX_MU_STAT_REG'Address use System'To_Address (16#2021_5064#);
   pragma Atomic (AUX_MU_STAT_REG);

   --  Mini Uart Baudrate
   AUX_MU_BAUD_REG : Register_32;
   for AUX_MU_BAUD_REG'Address use System'To_Address (16#2021_5068#);
   pragma Atomic (AUX_MU_BAUD_REG);

   --  SPI 1 Control register 0
   AUX_SPI0_CNTL0_REG : Register_32;
   for AUX_SPI0_CNTL0_REG'Address use System'To_Address (16#2021_5080#);
   pragma Atomic (AUX_SPI0_CNTL0_REG);

   --  SPI 1 Control register 1
   AUX_SPI0_CNTL1_REG : Register_32;
   for AUX_SPI0_CNTL1_REG'Address use System'To_Address (16#2021_5084#);
   pragma Atomic (AUX_SPI0_CNTL1_REG);

   --  SPI 1 Status
   AUX_SPI0_STAT_REG : Register_32;
   for AUX_SPI0_STAT_REG'Address use System'To_Address (16#2021_5088#);
   pragma Atomic (AUX_SPI0_STAT_REG);

   --  SPI 1 Data
   AUX_SPI0_IO_REG : Register_32;
   for AUX_SPI0_IO_REG'Address use System'To_Address (16#2021_5090#);
   pragma Atomic (AUX_SPI0_IO_REG);

   --  SPI 1 Peek
   AUX_SPI0_PEEK_REG : Register_32;
   for AUX_SPI0_PEEK_REG'Address use System'To_Address (16#2021_5094#);
   pragma Atomic (AUX_SPI0_PEEK_REG);

   --  SPI 2 Control register 0
   AUX_SPI1_CNTL0_REG : Register_32;
   for AUX_SPI1_CNTL0_REG'Address use System'To_Address (16#2021_50C0#);
   pragma Atomic (AUX_SPI1_CNTL0_REG);

   --  SPI 2 Control register 1
   AUX_SPI1_CNTL1_REG : Register_32;
   for AUX_SPI1_CNTL1_REG'Address use System'To_Address (16#2021_50C4#);
   pragma Atomic (AUX_SPI1_CNTL1_REG);

   --  SPI 2 Status
   AUX_SPI1_STAT_REG : Register_32;
   for AUX_SPI1_STAT_REG'Address use System'To_Address (16#2021_50C8#);
   pragma Atomic (AUX_SPI1_STAT_REG);

   --  SPI 2 Data
   AUX_SPI1_IO_REG : Register_32;
   for AUX_SPI1_IO_REG'Address use System'To_Address (16#2021_50D0#);
   pragma Atomic (AUX_SPI1_IO_REG);

   --  SPI 2 Peek
   AUX_SPI1_PEEK_REG : Register_32;
   for AUX_SPI1_PEEK_REG'Address use System'To_Address (16#2021_50D4#);
   pragma Atomic (AUX_SPI1_PEEK_REG);

   --  BSC : Broadcom Serial Controller

   --  BSC0

   --  BSC0: Control
   BSC0_C : Register_32;
   for BSC0_C'Address use System'To_Address (16#2020_5000#);
   pragma Atomic (BSC0_C);

   --  BSC0: Status
   BSC0_S : Register_32;
   for BSC0_S'Address use System'To_Address (16#2020_5004#);
   pragma Atomic (BSC0_S);

   --  BSC0: Data Length
   BSC0_DLEN : Register_32;
   for BSC0_DLEN'Address use System'To_Address (16#2020_5008#);
   pragma Atomic (BSC0_DLEN);

   --  BSC0: Slave Address
   BSC0_A : Register_32;
   for BSC0_A'Address use System'To_Address (16#2020_500C#);
   pragma Atomic (BSC0_A);

   --  BSC0: Data FIFO
   BSC0_FIFO : Register_32;
   for BSC0_FIFO'Address use System'To_Address (16#2020_5010#);
   pragma Atomic (BSC0_FIFO);

   --  BSC0: Clock Divider
   BSC0_DIV : Register_32;
   for BSC0_DIV'Address use System'To_Address (16#2020_5014#);
   pragma Atomic (BSC0_DIV);

   --  BSC0: Data Delay
   BSC0_DEL : Register_32;
   for BSC0_DEL'Address use System'To_Address (16#2020_5018#);
   pragma Atomic (BSC0_DEL);

   --  BSC0: Clock Stretch Iimeout
   BSC0_CLKT : Register_32;
   for BSC0_CLKT'Address use System'To_Address (16#2020_501C#);
   pragma Atomic (BSC0_CLKT);

   --  BSC1

   --  BSC1: Control
   BSC1_C : Register_32;
   for BSC1_C'Address use System'To_Address (16#2080_4000#);
   pragma Atomic (BSC1_C);

   --  BSC1: Status
   BSC1_S : Register_32;
   for BSC1_S'Address use System'To_Address (16#2080_4004#);
   pragma Atomic (BSC1_S);

   --  BSC1: Data Length
   BSC1_DLEN : Register_32;
   for BSC1_DLEN'Address use System'To_Address (16#2080_4008#);
   pragma Atomic (BSC1_DLEN);

   --  BSC1: Slave Address
   BSC1_A : Register_32;
   for BSC1_A'Address use System'To_Address (16#2080_400C#);
   pragma Atomic (BSC1_A);

   --  BSC1: Data FIFO
   BSC1_FIFO : Register_32;
   for BSC1_FIFO'Address use System'To_Address (16#2080_4010#);
   pragma Atomic (BSC1_FIFO);

   --  BSC1: Clock Divider
   BSC1_DIV : Register_32;
   for BSC1_DIV'Address use System'To_Address (16#2080_4014#);
   pragma Atomic (BSC1_DIV);

   --  BSC1: Data Delay
   BSC1_DEL : Register_32;
   for BSC1_DEL'Address use System'To_Address (16#2080_4018#);
   pragma Atomic (BSC1_DEL);

   --  BSC1: Clock Stretch Iimeout
   BSC1_CLKT : Register_32;
   for BSC1_CLKT'Address use System'To_Address (16#2080_401C#);
   pragma Atomic (BSC1_CLKT);

   --  BSC2 master is used dedicated with the HDMI interface and should not be
   --  accessed by user programs.

   --  There are 15 DMA channels. Each channel has 11 registers and only three
   --  (CS, CONBLK_AD and DEBUG) are directly writeable.

   --  DMA Channel 0 : CS
   DMA_CH0_CS : Register_32;
   for DMA_CH0_CS'Address use System'To_Address (16#2000_7000#);
   pragma Atomic (DMA_CH0_CS);

   --  DMA Channel 0 : CONBLK_AD
   DMA_CH0_CONBLK_AD : Register_32;
   for DMA_CH0_CONBLK_AD'Address use System'To_Address (16#2000_7004#);
   pragma Atomic (DMA_CH0_CONBLK_AD);

   --  DMA Channel 0 : DEBUG
   DMA_CH0_DEBUG : Register_32;
   for DMA_CH0_DEBUG'Address use System'To_Address (16#2000_7020#);
   pragma Atomic (DMA_CH0_DEBUG);

   --  DMA Channel 1 : CS
   DMA_CH1_CS : Register_32;
   for DMA_CH1_CS'Address use System'To_Address (16#2000_7100#);
   pragma Atomic (DMA_CH1_CS);

   --  DMA Channel 1 : CONBLK_AD
   DMA_CH1_CONBLK_AD : Register_32;
   for DMA_CH1_CONBLK_AD'Address use System'To_Address (16#2000_7104#);
   pragma Atomic (DMA_CH1_CONBLK_AD);

   --  DMA Channel 1 : DEBUG
   DMA_CH1_DEBUG : Register_32;
   for DMA_CH1_DEBUG'Address use System'To_Address (16#2000_7120#);
   pragma Atomic (DMA_CH1_DEBUG);

   --  DMA Channel 2 : CS
   DMA_CH2_CS : Register_32;
   for DMA_CH2_CS'Address use System'To_Address (16#2000_7200#);
   pragma Atomic (DMA_CH2_CS);

   --  DMA Channel 2 : CONBLK_AD
   DMA_CH2_CONBLK_AD : Register_32;
   for DMA_CH2_CONBLK_AD'Address use System'To_Address (16#2000_7204#);
   pragma Atomic (DMA_CH2_CONBLK_AD);

   --  DMA Channel 2 : DEBUG
   DMA_CH2_DEBUG : Register_32;
   for DMA_CH2_DEBUG'Address use System'To_Address (16#2000_7220#);
   pragma Atomic (DMA_CH2_DEBUG);

   --  DMA Channel 3 : CS
   DMA_CH3_CS : Register_32;
   for DMA_CH3_CS'Address use System'To_Address (16#2000_7300#);
   pragma Atomic (DMA_CH3_CS);

   --  DMA Channel 3 : CONBLK_AD
   DMA_CH3_CONBLK_AD : Register_32;
   for DMA_CH3_CONBLK_AD'Address use System'To_Address (16#2000_7304#);
   pragma Atomic (DMA_CH3_CONBLK_AD);

   --  DMA Channel 3 : DEBUG
   DMA_CH3_DEBUG : Register_32;
   for DMA_CH3_DEBUG'Address use System'To_Address (16#2000_7320#);
   pragma Atomic (DMA_CH3_DEBUG);

   --  DMA Channel 4 : CS
   DMA_CH4_CS : Register_32;
   for DMA_CH4_CS'Address use System'To_Address (16#2000_7400#);
   pragma Atomic (DMA_CH4_CS);

   --  DMA Channel 4 : CONBLK_AD
   DMA_CH4_CONBLK_AD : Register_32;
   for DMA_CH4_CONBLK_AD'Address use System'To_Address (16#2000_7404#);
   pragma Atomic (DMA_CH4_CONBLK_AD);

   --  DMA Channel 4 : DEBUG
   DMA_CH4_DEBUG : Register_32;
   for DMA_CH4_DEBUG'Address use System'To_Address (16#2000_7420#);
   pragma Atomic (DMA_CH4_DEBUG);

   --  DMA Channel 5 : CS
   DMA_CH5_CS : Register_32;
   for DMA_CH5_CS'Address use System'To_Address (16#2000_7500#);
   pragma Atomic (DMA_CH5_CS);

   --  DMA Channel 5 : CONBLK_AD
   DMA_CH5_CONBLK_AD : Register_32;
   for DMA_CH5_CONBLK_AD'Address use System'To_Address (16#2000_7504#);
   pragma Atomic (DMA_CH5_CONBLK_AD);

   --  DMA Channel 5 : DEBUG
   DMA_CH5_DEBUG : Register_32;
   for DMA_CH5_DEBUG'Address use System'To_Address (16#2000_7520#);
   pragma Atomic (DMA_CH5_DEBUG);

   --  DMA Channel 6 : CS
   DMA_CH6_CS : Register_32;
   for DMA_CH6_CS'Address use System'To_Address (16#2000_7600#);
   pragma Atomic (DMA_CH6_CS);

   --  DMA Channel 6 : CONBLK_AD
   DMA_CH6_CONBLK_AD : Register_32;
   for DMA_CH6_CONBLK_AD'Address use System'To_Address (16#2000_7604#);
   pragma Atomic (DMA_CH6_CONBLK_AD);

   --  DMA Channel 6 : DEBUG
   DMA_CH6_DEBUG : Register_32;
   for DMA_CH6_DEBUG'Address use System'To_Address (16#2000_7620#);
   pragma Atomic (DMA_CH6_DEBUG);

   --  DMA Channel 7 : CS
   DMA_CH7_CS : Register_32;
   for DMA_CH7_CS'Address use System'To_Address (16#2000_7700#);
   pragma Atomic (DMA_CH7_CS);

   --  DMA Channel 7 : CONBLK_AD
   DMA_CH7_CONBLK_AD : Register_32;
   for DMA_CH7_CONBLK_AD'Address use System'To_Address (16#2000_7704#);
   pragma Atomic (DMA_CH7_CONBLK_AD);

   --  DMA Channel 7 : DEBUG
   DMA_CH7_DEBUG : Register_32;
   for DMA_CH7_DEBUG'Address use System'To_Address (16#2000_7720#);
   pragma Atomic (DMA_CH7_DEBUG);

   --  DMA Channel 8 : CS
   DMA_CH8_CS : Register_32;
   for DMA_CH8_CS'Address use System'To_Address (16#2000_7800#);
   pragma Atomic (DMA_CH8_CS);

   --  DMA Channel 8 : CONBLK_AD
   DMA_CH8_CONBLK_AD : Register_32;
   for DMA_CH8_CONBLK_AD'Address use System'To_Address (16#2000_7804#);
   pragma Atomic (DMA_CH8_CONBLK_AD);

   --  DMA Channel 8 : DEBUG
   DMA_CH8_DEBUG : Register_32;
   for DMA_CH8_DEBUG'Address use System'To_Address (16#2000_7820#);
   pragma Atomic (DMA_CH8_DEBUG);

   --  DMA Channel 9 : CS
   DMA_CH9_CS : Register_32;
   for DMA_CH9_CS'Address use System'To_Address (16#2000_7900#);
   pragma Atomic (DMA_CH9_CS);

   --  DMA Channel 9 : CONBLK_AD
   DMA_CH9_CONBLK_AD : Register_32;
   for DMA_CH9_CONBLK_AD'Address use System'To_Address (16#2000_7904#);
   pragma Atomic (DMA_CH9_CONBLK_AD);

   --  DMA Channel 9 : DEBUG
   DMA_CH9_DEBUG : Register_32;
   for DMA_CH9_DEBUG'Address use System'To_Address (16#2000_7920#);
   pragma Atomic (DMA_CH9_DEBUG);

   --  DMA Channel A : CS
   DMA_CHA_CS : Register_32;
   for DMA_CHA_CS'Address use System'To_Address (16#2000_7A00#);
   pragma Atomic (DMA_CHA_CS);

   --  DMA Channel A : CONBLK_AD
   DMA_CHA_CONBLK_AD : Register_32;
   for DMA_CHA_CONBLK_AD'Address use System'To_Address (16#2000_7A04#);
   pragma Atomic (DMA_CHA_CONBLK_AD);

   --  DMA Channel A : DEBUG
   DMA_CHA_DEBUG : Register_32;
   for DMA_CHA_DEBUG'Address use System'To_Address (16#2000_7A20#);
   pragma Atomic (DMA_CHA_DEBUG);

   --  DMA Channel B : CS
   DMA_CHB_CS : Register_32;
   for DMA_CHB_CS'Address use System'To_Address (16#2000_7B00#);
   pragma Atomic (DMA_CHB_CS);

   --  DMA Channel B : CONBLK_AD
   DMA_CHB_CONBLK_AD : Register_32;
   for DMA_CHB_CONBLK_AD'Address use System'To_Address (16#2000_7B04#);
   pragma Atomic (DMA_CHB_CONBLK_AD);

   --  DMA Channel B : DEBUG
   DMA_CHB_DEBUG : Register_32;
   for DMA_CHB_DEBUG'Address use System'To_Address (16#2000_7B20#);
   pragma Atomic (DMA_CHB_DEBUG);

      --  DMA Channel C : CS
   DMA_CHC_CS : Register_32;
   for DMA_CHC_CS'Address use System'To_Address (16#2000_7C00#);
   pragma Atomic (DMA_CHC_CS);

   --  DMA Channel C : CONBLK_AD
   DMA_CHC_CONBLK_AD : Register_32;
   for DMA_CHC_CONBLK_AD'Address use System'To_Address (16#2000_7C04#);
   pragma Atomic (DMA_CHC_CONBLK_AD);

   --  DMA Channel C : DEBUG
   DMA_CHC_DEBUG : Register_32;
   for DMA_CHC_DEBUG'Address use System'To_Address (16#2000_7C20#);
   pragma Atomic (DMA_CHC_DEBUG);

   --  DMA Channel D : CS
   DMA_CHD_CS : Register_32;
   for DMA_CHD_CS'Address use System'To_Address (16#2000_7D00#);
   pragma Atomic (DMA_CHD_CS);

   --  DMA Channel D : CONBLK_AD
   DMA_CHD_CONBLK_AD : Register_32;
   for DMA_CHD_CONBLK_AD'Address use System'To_Address (16#2000_7D04#);
   pragma Atomic (DMA_CHD_CONBLK_AD);

   --  DMA Channel D : DEBUG
   DMA_CHD_DEBUG : Register_32;
   for DMA_CHD_DEBUG'Address use System'To_Address (16#2000_7D20#);
   pragma Atomic (DMA_CHD_DEBUG);

   --  DMA Channel E : CS
   DMA_CHE_CS : Register_32;
   for DMA_CHE_CS'Address use System'To_Address (16#2000_7E00#);
   pragma Atomic (DMA_CHE_CS);

   --  DMA Channel E : CONBLK_AD
   DMA_CHE_CONBLK_AD : Register_32;
   for DMA_CHE_CONBLK_AD'Address use System'To_Address (16#2000_7E04#);
   pragma Atomic (DMA_CHE_CONBLK_AD);

   --  DMA Channel E : DEBUG
   DMA_CHE_DEBUG : Register_32;
   for DMA_CHE_DEBUG'Address use System'To_Address (16#2000_7E20#);
   pragma Atomic (DMA_CHE_DEBUG);

   --  DMA Channel F has a different address base :  0x7EE05000 ,
   --  in Physical address space : 0x20E0_5000
   --  DMA Channel F : CS
   DMA_CHF_CS : Register_32;
   for DMA_CHF_CS'Address use System'To_Address (16#20E0_5000#);
   pragma Atomic (DMA_CHF_CS);

   --  DMA Channel F : CONBLK_AD
   DMA_CHF_CONBLK_AD : Register_32;
   for DMA_CHF_CONBLK_AD'Address use System'To_Address (16#20E0_5004#);
   pragma Atomic (DMA_CHF_CONBLK_AD);

   --  DMA Channel F : DEBUG
   DMA_CHF_DEBUG : Register_32;
   for DMA_CHF_DEBUG'Address use System'To_Address (16#20E0_5020#);
   pragma Atomic (DMA_CHF_DEBUG);

   --  DMA INT STATUS
   DMA_INT_STATUS : Register_32;
   for DMA_INT_STATUS'Address use System'To_Address (16#2000_7FE0#);
   pragma Atomic (DMA_INT_STATUS);

   --  DMA Global Enable Reg
   DMA_ENABLE : Register_32;
   for DMA_ENABLE'Address use System'To_Address (16#2000_7FF0#);
   pragma Atomic (DMA_ENABLE);

   --  DMA Control Block Data Structure
   type DMA_CTRL_BLOCK is record
      TI, SOURCE_AD, DEST_AD, TXFR_LEN, STRIDE, NEXTCONBK, Reserve1, Reserve2
        : Register_32;
   end record;
   for DMA_CTRL_BLOCK'Alignment use 32;  -- 256bits alignment

   --  EMMC ( External Mass Media Controller )
   --  Register Address Base: 0x7E30_0000 in VC space,
   --  0x2030_0000 in physical space.

   --  Argument for Command ACMD23:
   EMMC_ARG2 : Register_32;
   for EMMC_ARG2'Address use System'To_Address (16#2030_0000#);
   pragma Atomic (EMMC_ARG2);

   --  Block size and count:
   EMMC_BLKSIZECNT : Register_32;
   for EMMC_BLKSIZECNT'Address use System'To_Address (16#2030_0004#);
   pragma Atomic (EMMC_BLKSIZECNT);

   --  Argument for other command:
   EMMC_ARG1 : Register_32;
   for EMMC_ARG1'Address use System'To_Address (16#2030_0008#);
   pragma Atomic (EMMC_ARG1);

   --  Command and Transfer Mode
   EMMC_CMDTM : Register_32;
   for EMMC_CMDTM'Address use System'To_Address (16#2030_000C#);
   pragma Atomic (EMMC_CMDTM);

   --  Response bits 31:0
   EMMC_RESP0 : Register_32;
   for EMMC_RESP0'Address use System'To_Address (16#2030_0010#);
   pragma Atomic (EMMC_RESP0);

   --  Response bits 63:32
   EMMC_RESP1 : Register_32;
   for EMMC_RESP1'Address use System'To_Address (16#2030_0014#);
   pragma Atomic (EMMC_RESP1);

   --  Response bits 95:64
   EMMC_RESP2 : Register_32;
   for EMMC_RESP2'Address use System'To_Address (16#2030_0018#);
   pragma Atomic (EMMC_RESP2);

   --  Response bits 127:96
   EMMC_RESP3 : Register_32;
   for EMMC_RESP3'Address use System'To_Address (16#2030_001C#);
   pragma Atomic (EMMC_RESP3);

   --  Data
   EMMC_DATA : Register_32;
   for EMMC_DATA'Address use System'To_Address (16#2030_0020#);
   pragma Atomic (EMMC_DATA);

   --  STATUS
   EMMC_STATUS : Register_32;
   for EMMC_STATUS'Address use System'To_Address (16#2030_0024#);
   pragma Atomic (EMMC_STATUS);

   --  Host Configuration bits
   EMMC_CONTROL0 : Register_32;
   for EMMC_CONTROL0'Address use System'To_Address (16#2030_0028#);
   pragma Atomic (EMMC_CONTROL0);

   --  Host Configuration bits
   EMMC_CONTROL1 : Register_32;
   for EMMC_CONTROL1'Address use System'To_Address (16#2030_002C#);
   pragma Atomic (EMMC_CONTROL1);

   --  Interrupt Flags
   EMMC_INTERRUPT : Register_32;
   for EMMC_INTERRUPT'Address use System'To_Address (16#2030_0030#);
   pragma Atomic (EMMC_INTERRUPT);

   --  Interrupt Flag Enable
   EMMC_IRPT_MASK : Register_32;
   for EMMC_IRPT_MASK'Address use System'To_Address (16#2030_0034#);
   pragma Atomic (EMMC_IRPT_MASK);

   --  Interrupt Generation Enable
   EMMC_IRPT_EN : Register_32;
   for EMMC_IRPT_EN'Address use System'To_Address (16#2030_0038#);
   pragma Atomic (EMMC_IRPT_EN);

   --  GPIO

   --  GPIO Function Select 0 .. 5
   type GPFSEL_Array is array (0 .. 5) of Register_32;
   pragma Atomic_Components (GPFSEL_Array);
   GPFSEL : GPFSEL_Array;
   for GPFSEL'Address use System'To_Address (16#2020_0000#);

   --  GPIO Pin Output Set 0 .. 1
   type GPSET_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPSET_Array);
   GPSET : GPSET_Array;
   for GPSET'Address use System'To_Address (16#2020_001C#);

   --  GPIO Pin Output Clear 0 .. 1
   type GPCLR_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPCLR_Array);
   GPCLR : GPCLR_Array;
   for GPCLR'Address use System'To_Address (16#2020_0028#);

   --  GPIO Pin Level 0 .. 1
   type GPLEV_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPLEV_Array);
   GPLEV : GPLEV_Array;
   for GPLEV'Address use System'To_Address (16#2020_0034#);

   --  GPIO Pin Event Detect Status 0 .. 1
   type GPEDS_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPEDS_Array);
   GPEDS : GPEDS_Array;
   for GPEDS'Address use System'To_Address (16#2020_0040#);

   --  GPIO Pin Rising Edge Detect Enable 0 .. 1
   type GPREN_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPREN_Array);
   GPREN : GPREN_Array;
   for GPREN'Address use System'To_Address (16#2020_004C#);

   --  GPIO Pin Falling Edge Detect Enable 0 .. 1
   type GPFEN_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPFEN_Array);
   GPFEN : GPFEN_Array;
   for GPFEN'Address use System'To_Address (16#2020_0058#);

   --  GPIO Pin High Detect Enable 0 .. 1
   type GPHEN_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPHEN_Array);
   GPHEN : GPHEN_Array;
   for GPHEN'Address use System'To_Address (16#2020_0064#);

   --  GPIO Pin Low Detect Enable 0 .. 1
   type GPLEN_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPLEN_Array);
   GPLEN : GPLEN_Array;
   for GPLEN'Address use System'To_Address (16#2020_0070#);

   --  GPIO Pin Async. Rising Edge Detect Enable 0 .. 1
   type GPAREN_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPAREN_Array);
   GPAREN : GPAREN_Array;
   for GPAREN'Address use System'To_Address (16#2020_007C#);

   --  GPIO Pin Async. Falling Edge Detect Enable 0 .. 1
   type GPAFEN_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPAFEN_Array);
   GPAFEN : GPAFEN_Array;
   for GPAFEN'Address use System'To_Address (16#2020_0088#);

   --  GPIO Pin Pull-up/down Enable
   GPPUD : Register_32;
   for GPPUD'Address use System'To_Address (16#2020_0094#);
   pragma Atomic (GPPUD);

   --  GPIO Pin Pull-up/down Enable Clock 0 .. 1
   type GPPUDCLK_Array is array (0 .. 1) of Register_32;
   pragma Atomic_Components (GPPUDCLK_Array);
   GPPUDCLK : GPPUDCLK_Array;
   for GPPUDCLK'Address use System'To_Address (16#2020_0098#);

   --  The General Purpose clocks can be output to GPIO pins.

   --  Clock Manager General Purpose Clocks Control
   --  CM_GP0CTL, CM_GP1CTL, CM_GP2CTL

   --  CM_GP0CTL
   CM_GP0CTL : Register_32;
   for CM_GP0CTL'Address use System'To_Address (16#2010_1070#);
   pragma Atomic (CM_GP0CTL);

   --  CM_GP1CTL
   CM_GP1CTL : Register_32;
   for CM_GP1CTL'Address use System'To_Address (16#2010_1078#);
   pragma Atomic (CM_GP1CTL);

   --  CM_GP2CTL
   CM_GP2CTL : Register_32;
   for CM_GP2CTL'Address use System'To_Address (16#2010_1080#);
   pragma Atomic (CM_GP2CTL);

   --  Clock Manager General Purpose Clock Divisors
   --  CM_GP0DIV, CM_GP1DIV, CM_GP2DIV

   --  CM_GP0DIV
   CM_GP0DIV : Register_32;
   for CM_GP0DIV'Address use System'To_Address (16#2010_1074#);
   pragma Atomic (CM_GP0DIV);

   --  CM_GP1DIV
   CM_GP1DIV : Register_32;
   for CM_GP1DIV'Address use System'To_Address (16#2010_107C#);
   pragma Atomic (CM_GP1DIV);

   --  CM_GP2DIV
   CM_GP2DIV : Register_32;
   for CM_GP2DIV'Address use System'To_Address (16#2010_1084#);
   pragma Atomic (CM_GP2DIV);

   --  ARM Interrupt Register

   --  IRQ Basic Pending
   IRQ_Basic_Pending : Register_32;
   for IRQ_Basic_Pending'Address use System'To_Address (16#2000_B200#);
   pragma Atomic (IRQ_Basic_Pending);

   --  IRQ Pending 1
   IRQ_Pending1 : Register_32;
   for IRQ_Pending1'Address use System'To_Address (16#2000_B204#);
   pragma Atomic (IRQ_Pending1);

   --  IRQ Pending 2
   IRQ_Pending2 : Register_32;
   for IRQ_Pending2'Address use System'To_Address (16#2000_B208#);
   pragma Atomic (IRQ_Pending2);

   --  FIQ Control
   FIQ_CTRL : Register_32;
   for FIQ_CTRL'Address use System'To_Address (16#2000_B20C#);
   pragma Atomic (FIQ_CTRL);

   --  Enable IRQs 1
   IRQ_ENABLE1 : Register_32;
   for IRQ_ENABLE1'Address use System'To_Address (16#2000_B210#);
   pragma Atomic (IRQ_ENABLE1);

   --  Enable IRQs 2
   IRQ_ENABLE2 : Register_32;
   for IRQ_ENABLE2'Address use System'To_Address (16#2000_B214#);
   pragma Atomic (IRQ_ENABLE2);

   --  Enable Basic IRQs
   IRQ_ENABLE_BASIC : Register_32;
   for IRQ_ENABLE_BASIC'Address use System'To_Address (16#2000_B218#);
   pragma Atomic (IRQ_ENABLE_BASIC);

   --  Disable IRQs 1
   IRQ_DISABLE1 : Register_32;
   for IRQ_DISABLE1'Address use System'To_Address (16#2000_B21C#);
   pragma Atomic (IRQ_DISABLE1);

   --  Disable IRQs 2
   IRQ_DISABLE2 : Register_32;
   for IRQ_DISABLE2'Address use System'To_Address (16#2000_B220#);
   pragma Atomic (IRQ_DISABLE2);

   --  Disable Basic IRQs
   IRQ_DISABLE_BASIC : Register_32;
   for IRQ_DISABLE_BASIC'Address use System'To_Address (16#2000_B224#);
   pragma Atomic (IRQ_DISABLE_BASIC);

   --  PCM/I2S Audio
   --  There is only PCM module in the BCM2835. The PCM base address for the
   --  registersis 0x7E203000 in VC space, 0x20203000 in physical space

   --  PCM Control and Status
   PCM_CS_A : Register_32;
   for PCM_CS_A'Address use System'To_Address (16#2020_3000#);
   pragma Atomic (PCM_CS_A);

   --  PCM FIFO DATA
   PCM_FIFO_A : Register_32;
   for PCM_FIFO_A'Address use System'To_Address (16#2020_3004#);
   pragma Atomic (PCM_FIFO_A);

   --  PCM Mode
   PCM_MODE_A : Register_32;
   for PCM_MODE_A'Address use System'To_Address (16#2020_3008#);
   pragma Atomic (PCM_MODE_A);

   --  PCM Receive Configuration
   PCM_RXC_A : Register_32;
   for PCM_RXC_A'Address use System'To_Address (16#2020_300C#);
   pragma Atomic (PCM_RXC_A);

   --  PCM Transmit Configuration
   PCM_TXC_A : Register_32;
   for PCM_TXC_A'Address use System'To_Address (16#2020_3010#);
   pragma Atomic (PCM_TXC_A);

   --  PCM DMA Request Level
   PCM_DREQ_A : Register_32;
   for PCM_DREQ_A'Address use System'To_Address (16#2020_3014#);
   pragma Atomic (PCM_DREQ_A);

   --  PCM Interrupt Enables
   PCM_INTEN_A : Register_32;
   for PCM_INTEN_A'Address use System'To_Address (16#2020_3018#);
   pragma Atomic (PCM_INTEN_A);

   --  PCM Interrupt Status & Clear
   PCM_INTSTC_A : Register_32;
   for PCM_INTSTC_A'Address use System'To_Address (16#2020_301C#);
   pragma Atomic (PCM_INTSTC_A);

   --  PCM Gray Mode Control
   PCM_GRAY : Register_32;
   for PCM_GRAY'Address use System'To_Address (16#2020_3020#);
   pragma Atomic (PCM_GRAY);

   --  Pulse Width Modulator
   --  Address base is missing in BCM2835-ARM-Peripherals.pdf
   --  the value given is only a placeholder

   PWMCLK_CNTL : Register_32;
   for PWMCLK_CNTL'Address use System'To_Address (16#2010_10a0#);
   --  CLOCK_BASE + 4*BCM2835_PWMCLK_CNTL
   pragma Atomic (PWMCLK_CNTL);

   PWMCLK_DIV : Register_32;
   for PWMCLK_DIV'Address use System'To_Address (16#2010_10a4#);
   --  CLOCK_BASE + 4*BCM2835_PWMCLK_DIV
   pragma Atomic (PWMCLK_DIV);

   PWM_ADDRESS_BASE : constant := 16#2020_c000#;

   PWM_CONTROL : Register_32;
   for PWM_CONTROL'Address use System'To_Address (16#2020_c000#);
   --  PWM_BASE + 4*BCM2835_PWM_CONTROL
   pragma Atomic (PWM_CONTROL);

   PWM_FIFO_STATUS : Register_32;
   for PWM_FIFO_STATUS'Address use System'To_Address (16#2020_c004#);
   --  PWM_FIFO_STATUS
   pragma Atomic (PWM_FIFO_STATUS);

   --  PWM DMA Configuration
   PWM_DMAC : Register_32;
   for PWM_DMAC'Address use System'To_Address (PWM_ADDRESS_BASE + 16#08#);
   pragma Atomic (PWM_DMAC);

   PWM0_RANGE : Register_32;
   for PWM0_RANGE'Address use System'To_Address (16#2020_c010#);
   --  PWM_BASE + 4*BCM2835_PWM0_RANGE
   pragma Atomic (PWM0_RANGE);

   --  PWM Channel 1 Data
   PWM1_DATA : Register_32;
   for PWM1_DATA'Address use System'To_Address (PWM_ADDRESS_BASE + 16#14#);
   pragma Atomic (PWM1_DATA);

   PWM_FIFO_DATA : Register_32;
   for PWM_FIFO_DATA'Address use System'To_Address (16#2020_c018#);
   --  PWM_FIFO_DATA
   pragma Atomic (PWM_FIFO_DATA);

   PWM1_RANGE : Register_32;
   for PWM1_RANGE'Address use System'To_Address (16#2020_c020#);
   --  PWM_BASE + 4*BCM2835_PWM1_RANGE
   pragma Atomic (PWM1_RANGE);

   --  PWM Channel 2 Data
   PWM2_DATA : Register_32;
   for PWM2_DATA'Address use System'To_Address (PWM_ADDRESS_BASE + 16#24#);
   pragma Atomic (PWM2_DATA);

   --  SPI Master Address Map
   --  This is the SPI0, the full functional. SPI1 and SPI2 in AUXIO are mini
   --  master version
   SPI0_ADDRESS_BASE : constant := 16#2020_4000#;

   --  SPI Master Control and Status
   SPI0_CS : Register_32;
   for SPI0_CS'Address use System'To_Address (SPI0_ADDRESS_BASE + 16#00#);
   pragma Atomic (SPI0_CS);

   --  SPI Master TX and RX FIFOs
   SPI0_FIFO : Register_32;
   for SPI0_FIFO'Address use System'To_Address (SPI0_ADDRESS_BASE + 16#04#);
   pragma Atomic (SPI0_FIFO);

   --  SPI Master Clock Divider
   SPI0_CLK : Register_32;
   for SPI0_CLK'Address use System'To_Address (SPI0_ADDRESS_BASE + 16#08#);
   pragma Atomic (SPI0_CLK);

   --  SPI Master Data Length
   SPI0_DLEN : Register_32;
   for SPI0_DLEN'Address use System'To_Address (SPI0_ADDRESS_BASE + 16#0C#);
   pragma Atomic (SPI0_DLEN);

   --  SPI LOSSI mode TOH
   SPI0_LTOH : Register_32;
   for SPI0_LTOH'Address use System'To_Address (SPI0_ADDRESS_BASE + 16#10#);
   pragma Atomic (SPI0_LTOH);

   --  SPI DMA DREQ Controls
   SPI0_DC : Register_32;
   for SPI0_DC'Address use System'To_Address (SPI0_ADDRESS_BASE + 16#14#);
   pragma Atomic (SPI0_DC);

   --  SPI/BSC Slave Address Map
   --  BSC interface can be used as either a Broadcom Serial Controller(BSC)
   --  or a Serial Peripheral Interface (SPI) controller. BSC bus is a
   --  proprietary bus compliant with the Philps I2C bus/interface
   --  version 2.1 Jan. 2000.
   --
   I2C_SPI_SLV_ADDRESS_BASE : constant := 16#2021_4000#;

   --  Data Register
   I2C_SPI_SLV_DR : Register_32;
   for I2C_SPI_SLV_DR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#00#);
   pragma Atomic (I2C_SPI_SLV_DR);

   --  Status and error clear
   I2C_SPI_SLV_RSR : Register_32;
   for I2C_SPI_SLV_RSR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#04#);
   pragma Atomic (I2C_SPI_SLV_RSR);

   --  I2C slave address value
   I2C_SPI_SLV_SLV : Register_32;
   for I2C_SPI_SLV_SLV'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#08#);
   pragma Atomic (I2C_SPI_SLV_SLV);

   --  Control Register
   I2C_SPI_SLV_CR : Register_32;
   for I2C_SPI_SLV_CR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#0C#);
   pragma Atomic (I2C_SPI_SLV_CR);

   --  Flag Register
   I2C_SPI_SLV_FR : Register_32;
   for I2C_SPI_SLV_FR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#10#);
   pragma Atomic (I2C_SPI_SLV_FR);

   --  Interrupt fifo level select Register
   I2C_SPI_SLV_IFLS : Register_32;
   for I2C_SPI_SLV_IFLS'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#14#);
   pragma Atomic (I2C_SPI_SLV_IFLS);

   --  Interrupt Mask Set Clear Register
   I2C_SPI_SLV_IMSC : Register_32;
   for I2C_SPI_SLV_IMSC'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#18#);
   pragma Atomic (I2C_SPI_SLV_IMSC);

   --  Raw Interrupt Status Register
   I2C_SPI_SLV_RIS : Register_32;
   for I2C_SPI_SLV_RIS'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#1c#);
   pragma Atomic (I2C_SPI_SLV_RIS);

   --  Masked Interupt Status Register
   I2C_SPI_SLV_MIS : Register_32;
   for I2C_SPI_SLV_MIS'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#20#);
   pragma Atomic (I2C_SPI_SLV_MIS);

   --  Interupt Clear Register
   I2C_SPI_SLV_ICR : Register_32;
   for I2C_SPI_SLV_ICR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#24#);
   pragma Atomic (I2C_SPI_SLV_ICR);

   --  DMA Control Register
   I2C_SPI_SLV_DMACR : Register_32;
   for I2C_SPI_SLV_DMACR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#28#);
   pragma Atomic (I2C_SPI_SLV_DMACR);

   --  FIFO Test Data Register
   I2C_SPI_SLV_TDR : Register_32;
   for I2C_SPI_SLV_TDR'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#2C#);
   pragma Atomic (I2C_SPI_SLV_TDR);

   --  GPU Status Register
   I2C_SPI_SLV_GPUSTAT : Register_32;
   for I2C_SPI_SLV_GPUSTAT'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#30#);
   pragma Atomic (I2C_SPI_SLV_GPUSTAT);

   --  Host Control Register
   I2C_SPI_SLV_HCTRL : Register_32;
   for I2C_SPI_SLV_HCTRL'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#34#);
   pragma Atomic (I2C_SPI_SLV_HCTRL);

   --  I2C Debug Register
   I2C_SPI_SLV_DEBUG1 : Register_32;
   for I2C_SPI_SLV_DEBUG1'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#38#);
   pragma Atomic (I2C_SPI_SLV_DEBUG1);

   --  SPI Debug Register
   I2C_SPI_SLV_DEBUG2 : Register_32;
   for I2C_SPI_SLV_DEBUG2'Address use
     System'To_Address (I2C_SPI_SLV_ADDRESS_BASE + 16#3C#);
   pragma Atomic (I2C_SPI_SLV_DEBUG2);

   --  System Timer Register
   --
   ST_ADDRESS_BASE : constant := 16#2000_3000#;

   --  System Timer Control / Status
   ST_CS : Register_32;
   for ST_CS'Address use System'To_Address (ST_ADDRESS_BASE + 16#00#);
   pragma Atomic (ST_CS);

   --  System Timer Counter Lower 32 bits
   ST_CLO : Register_32;
   for ST_CLO'Address use System'To_Address (ST_ADDRESS_BASE + 16#04#);
   pragma Atomic (ST_CLO);

   --  System Timer Counter Higher 32 bits
   ST_CHI : Register_32;
   for ST_CHI'Address use System'To_Address (ST_ADDRESS_BASE + 16#08#);
   pragma Atomic (ST_CHI);

   --  System Timer Compare 0
   ST_C0 : Register_32;
   for ST_C0'Address use System'To_Address (ST_ADDRESS_BASE + 16#0C#);
   pragma Atomic (ST_C0);

   --  System Timer Compare 1
   ST_C1 : Register_32;
   for ST_C1'Address use System'To_Address (ST_ADDRESS_BASE + 16#10#);
   pragma Atomic (ST_C1);

   --  System Timer Compare 2
   ST_C2 : Register_32;
   for ST_C2'Address use System'To_Address (ST_ADDRESS_BASE + 16#14#);
   pragma Atomic (ST_C2);

   --  System Timer Compare 3
   ST_C3 : Register_32;
   for ST_C3'Address use System'To_Address (ST_ADDRESS_BASE + 16#18#);
   pragma Atomic (ST_C3);

   --  UART Address Map
   --
   UART_ADDRESS_BASE : constant := 16#2020_1000#;

   --  Data Register
   UART_DR : Register_32;
   for UART_DR'Address use System'To_Address (UART_ADDRESS_BASE + 16#00#);
   pragma Atomic (UART_DR);

   --  receive status register/error clear register
   UART_RSRECR : Register_32;
   for UART_RSRECR'Address use System'To_Address (UART_ADDRESS_BASE + 16#04#);
   pragma Atomic (UART_RSRECR);

   --  Flag Register
   UART_FR : Register_32;
   for UART_FR'Address use System'To_Address (UART_ADDRESS_BASE + 16#18#);
   pragma Atomic (UART_FR);

   --  not in use
   UART_ILPR : Register_32;
   for UART_ILPR'Address use System'To_Address (UART_ADDRESS_BASE + 16#20#);
   pragma Atomic (UART_ILPR);

   --  Integer Baud rate divisor
   UART_IBRD : Register_32;
   for UART_IBRD'Address use System'To_Address (UART_ADDRESS_BASE + 16#24#);
   pragma Atomic (UART_IBRD);

   --  Fractional Baud rate divisor
   UART_FBRD : Register_32;
   for UART_FBRD'Address use System'To_Address (UART_ADDRESS_BASE + 16#28#);
   pragma Atomic (UART_FBRD);

   --  Line Control Register
   UART_LCRH : Register_32;
   for UART_LCRH'Address use System'To_Address (UART_ADDRESS_BASE + 16#2C#);
   pragma Atomic (UART_LCRH);

   --  Control Register
   UART_CR : Register_32;
   for UART_CR'Address use System'To_Address (UART_ADDRESS_BASE + 16#30#);
   pragma Atomic (UART_CR);

   --  Interupt FIFO Level Select Register
   UART_IFLS : Register_32;
   for UART_IFLS'Address use System'To_Address (UART_ADDRESS_BASE + 16#34#);
   pragma Atomic (UART_IFLS);

   --  Interupt Mask Set Clear Register
   UART_IMSC : Register_32;
   for UART_IMSC'Address use System'To_Address (UART_ADDRESS_BASE + 16#38#);
   pragma Atomic (UART_IMSC);

   --  Raw Interupt Status Register
   UART_RIS : Register_32;
   for UART_RIS'Address use System'To_Address (UART_ADDRESS_BASE + 16#3C#);
   pragma Atomic (UART_RIS);

   --  Masked Interupt Status Register
   UART_MIS : Register_32;
   for UART_MIS'Address use System'To_Address (UART_ADDRESS_BASE + 16#40#);
   pragma Atomic (UART_MIS);

   --  Interupt Clear Register
   UART_ICR : Register_32;
   for UART_ICR'Address use System'To_Address (UART_ADDRESS_BASE + 16#44#);
   pragma Atomic (UART_ICR);

   --  DMA Control Register
   UART_DMACR : Register_32;
   for UART_DMACR'Address use System'To_Address (UART_ADDRESS_BASE + 16#48#);
   pragma Atomic (UART_DMACR);

   --  Integration Test Control Register
   UART_ITCR : Register_32;
   for UART_ITCR'Address use System'To_Address (UART_ADDRESS_BASE + 16#80#);
   pragma Atomic (UART_ITCR);

   --  Integration test input Register
   UART_ITIP : Register_32;
   for UART_ITIP'Address use System'To_Address (UART_ADDRESS_BASE + 16#84#);
   pragma Atomic (UART_ITIP);

   --  Integration test output Register
   UART_ITOP : Register_32;
   for UART_ITOP'Address use System'To_Address (UART_ADDRESS_BASE + 16#88#);
   pragma Atomic (UART_ITOP);

   --  Test Data Register
   UART_TDR : Register_32;
   for UART_TDR'Address use System'To_Address (UART_ADDRESS_BASE + 16#8C#);
   pragma Atomic (UART_TDR);

   --  Timer(ARM side) Address Map
   --
   AT_ADDRESS_BASE : constant := 16#2000_B000#;

   --  Load Register
   AT_LOAD : Register_32;
   for AT_LOAD'Address use System'To_Address (AT_ADDRESS_BASE + 16#0400#);
   pragma Atomic (AT_LOAD);

   --  Value Register
   AT_VALUE : Register_32;
   for AT_VALUE'Address use System'To_Address (AT_ADDRESS_BASE + 16#0404#);
   pragma Atomic (AT_VALUE);

   --  Control Register
   AT_CTL : Register_32;
   for AT_CTL'Address use System'To_Address (AT_ADDRESS_BASE + 16#0408#);
   pragma Atomic (AT_CTL);

   --  IRQ Clear/Ack Register
   AT_IRQCA : Register_32;
   for AT_IRQCA'Address use System'To_Address (AT_ADDRESS_BASE + 16#040C#);
   pragma Atomic (AT_IRQCA);

   --  Raw IRQ Register
   AT_RIRQ : Register_32;
   for AT_RIRQ'Address use System'To_Address (AT_ADDRESS_BASE + 16#0410#);
   pragma Atomic (AT_RIRQ);

   --  Masked IRQ Register
   AT_MIRQ : Register_32;
   for AT_MIRQ'Address use System'To_Address (AT_ADDRESS_BASE + 16#0414#);
   pragma Atomic (AT_MIRQ);

   --  reload Register
   AT_RELOAD : Register_32;
   for AT_RELOAD'Address use System'To_Address (AT_ADDRESS_BASE + 16#0418#);
   pragma Atomic (AT_RELOAD);

   --  pre-divider Register
   AT_PREDIV : Register_32;
   for AT_PREDIV'Address use System'To_Address (AT_ADDRESS_BASE + 16#041C#);
   pragma Atomic (AT_PREDIV);

   --  Free running counter Register
   AT_FRCNT : Register_32;
   for AT_FRCNT'Address use System'To_Address (AT_ADDRESS_BASE + 16#0420#);
   pragma Atomic (AT_FRCNT);

   --  USB
end System.BB.Board_Support.Bcm2835;
