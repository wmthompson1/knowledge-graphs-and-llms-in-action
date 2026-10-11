-- do not update 
USE [LIVE]
GO

/****** Object:  Trigger [dbo].[UPDATE_PAYABLE]    Script Date: 8/5/2026 1:12:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---CREATE TRIGGER [dbo].UPDATE_PAYABLE ON [dbo].[PAYABLE] FOR UPDATE AS  
DECLARE  
 @nRcd INT,  
 @N_VOUCHER_ID NVARCHAR(15),  
 @N_PAY_STATUS NCHAR,  
 @N_VENDOR_ID NVARCHAR(15),  
 @N_TOTAL_AMOUNT DECIMAL(23,8),  
 @N_PAID_AMOUNT DECIMAL(23,8),  
 @N_LAST_PAID_DATE DATETIME,  
 @N_SELL_RATE DECIMAL(15,8),  
 @O_VOUCHER_ID NVARCHAR(15),  
 @O_PAY_STATUS NCHAR,  
 @O_VENDOR_ID NVARCHAR(15),  
 @O_TOTAL_AMOUNT DECIMAL(23,8),  
 @O_PAID_AMOUNT DECIMAL(23,8),  
 @O_SELL_RATE DECIMAL(15,8),   
 @N_SITE_ID NVARCHAR(15),  
 @WORKORDER_TYPE NVARCHAR(3),  
 @WORKORDER_BASE_ID NVARCHAR(30),  
 @WORKORDER_LOT_ID NVARCHAR(3),  
 @WORKORDER_SPLIT_ID NVARCHAR(3),  
 @COST_CATEGORY NCHAR(1),  
 @AMOUNT DECIMAL(23,8),  
 @FIXED_Charge DECIMAL(23,8),  
 @MATL_COST DECIMAL(23,8),  
 @SERV_COST DECIMAL(23,8),  
 @nCurrDigits INT,  
 @nCost DEC(23,8),  
--rsd108661.180
 @sEntityID                  NVARCHAR(15),
 @bDoAdjust BIT  
IF NOT ( UPDATE(TYPE) OR UPDATE(PAY_STATUS) OR UPDATE(TERMS_DISC_TYPE) OR UPDATE(REPORT_1099_MISC) OR UPDATE(MARKED_FOR_PURGE) OR UPDATE(SELL_RATE) OR UPDATE(VENDOR_ID) OR UPDATE(SITE_ID) OR UPDATE(PAYB_GL_ACCT_ID) OR UPDATE(TOTAL_AMOUNT) OR UPDATE(PAID_AMOUNT) OR UPDATE(DISCOUNT_TAKEN) OR UPDATE(TERMS_NET_TYPE) )  
 RETURN  
SELECT @nRcd = 0  
SET NOCOUNT ON  
--bwb108661.167 select @nCurrDigits = c.i_curr_digits from CURRENCY c,APPLICATION_GLOBAL a where c.id = a.system_currency_id  
IF EXISTS( SELECT VENDOR_ID FROM INSERTED WHERE VENDOR_ID IS NULL AND TYPE <> 'W' )  
 SELECT @nRcd = 31290  
IF @nRcd = 0  
BEGIN  
DECLARE PAYABLE_UPD CURSOR LOCAL FOR  
 SELECT  
 I.VOUCHER_ID, I.PAY_STATUS, I.VENDOR_ID, I.TOTAL_AMOUNT, I.PAID_AMOUNT, I.LAST_PAID_DATE, I.SELL_RATE, I.SITE_ID,  
 D.VOUCHER_ID, D.PAY_STATUS, D.VENDOR_ID, D.TOTAL_AMOUNT, D.PAID_AMOUNT, D.SELL_RATE  
 FROM INSERTED I, DELETED D WHERE I.ROWID = D.ROWID  
OPEN PAYABLE_UPD  
FETCH PAYABLE_UPD INTO  
 @N_VOUCHER_ID, @N_PAY_STATUS, @N_VENDOR_ID, @N_TOTAL_AMOUNT, @N_PAID_AMOUNT, @N_LAST_PAID_DATE, @N_SELL_RATE, @N_SITE_ID,  
 @O_VOUCHER_ID, @O_PAY_STATUS, @O_VENDOR_ID, @O_TOTAL_AMOUNT, @O_PAID_AMOUNT, @O_SELL_RATE  
WHILE (@nRcd = 0 and @@FETCH_STATUS <> -1)  
BEGIN  
 EXEC EXE_STATUS_EVENT 'V', @N_VOUCHER_ID, NULL, NULL, 'U', @O_PAY_STATUS, @N_PAY_STATUS  
 IF @N_VOUCHER_ID != @O_VOUCHER_ID  
 BEGIN  
 update PAYABLE_LINE set VOUCHER_ID = @N_VOUCHER_ID where VOUCHER_ID = @O_VOUCHER_ID  
 update PAYABLE_DIST set VOUCHER_ID = @N_VOUCHER_ID where VOUCHER_ID = @O_VOUCHER_ID  
 update CREDIT_MEMO_APPLY set INV_VOUCHER_ID = @N_VOUCHER_ID where INV_VOUCHER_ID = @O_VOUCHER_ID  
 update CREDIT_MEMO_APPLY set MEMO_VOUCHER_ID = @N_VOUCHER_ID where MEMO_VOUCHER_ID = @O_VOUCHER_ID  
 update CASH_DISBURSE_LINE set VOUCHER_ID = @N_VOUCHER_ID where VOUCHER_ID = @O_VOUCHER_ID  
 update PAYABLE_CURR set VOUCHER_ID = @N_VOUCHER_ID where VOUCHER_ID = @O_VOUCHER_ID  
 END  
 IF @N_VENDOR_ID != @O_VENDOR_ID  
 OR @N_PAY_STATUS != @O_PAY_STATUS  
 OR @N_TOTAL_AMOUNT != @O_TOTAL_AMOUNT  
 OR @N_PAID_AMOUNT != @O_PAID_AMOUNT  
 OR @N_SELL_RATE != @O_SELL_RATE  
 BEGIN  
 If @nRcd = 0 And @N_PAID_AMOUNT > 0 And @N_PAID_AMOUNT > @N_TOTAL_AMOUNT  
 SELECT @nRcd = 31299  
 If @nRcd = 0 And @N_PAID_AMOUNT < 0 And @N_PAID_AMOUNT < @N_TOTAL_AMOUNT  
 SELECT @nRcd = 31299  
 IF @nRcd = 0  
 BEGIN  
 If @O_TOTAL_AMOUNT != @O_PAID_AMOUNT And @N_TOTAL_AMOUNT = @N_PAID_AMOUNT  
 update PAYABLE set zero_date = ISNULL( @N_LAST_PAID_DATE, GetDate()) where voucher_id = @O_VOUCHER_ID  
 If @O_TOTAL_AMOUNT = @O_PAID_AMOUNT And @N_TOTAL_AMOUNT != @N_PAID_AMOUNT  
 update PAYABLE set zero_date = NULL where voucher_id = @N_VOUCHER_ID  
 END  
 --LGP438520 Check for null vendor id - for WIP, both New and Old will be null (and for AP, both will be non-null) so it won't matter which we check (old or new).
 IF @nRcd = 0 AND @N_VENDOR_ID IS NOT NULL 
 BEGIN  
  --bwb108661.167
  --select @nCurrDigits = c.i_curr_digits from CURRENCY c, ACCOUNTING_ENTITY ae, SITE s where s.id = @N_SITE_ID and ae.id = s.entity_id and ae.functional_currency_id = c.id
  --rsd108661.180
  select @nCurrDigits = c.i_curr_digits, @sEntityID = s.entity_id from CURRENCY c, ACCOUNTING_ENTITY ae, SITE s where s.id = @N_SITE_ID and ae.id = s.entity_id and ae.functional_currency_id = c.id
  If @O_PAY_STATUS != 'L'  
   --update VENDOR set 
   --total_open_payb = total_open_payb - ROUND((@O_TOTAL_AMOUNT - @O_PAID_AMOUNT) * @O_SELL_RATE, @nCurrDigits), 
   --open_payb_count = open_payb_count - 1 
   --where id = @O_VENDOR_ID  
   --rsd108661.180
   IF NOT EXISTS ( SELECT VENDOR_ID FROM VENDOR_ENTITY WHERE vendor_id = @O_VENDOR_ID and entity_id = @sEntityID )
     INSERT INTO VENDOR_ENTITY ( VENDOR_ID, ENTITY_ID ) VALUES ( @O_VENDOR_ID, @sEntityID ) 
   update VENDOR_ENTITY set 
   total_open_payb = total_open_payb - ROUND((@O_TOTAL_AMOUNT - @O_PAID_AMOUNT) * @O_SELL_RATE, @nCurrDigits), 
   open_payb_count = open_payb_count - 1  
   where vendor_id = @O_VENDOR_ID and entity_id = @sEntityID 
  If @N_PAY_STATUS != 'X' And @N_PAY_STATUS != 'L'  
   --update VENDOR set 
   --total_open_payb = total_open_payb + ROUND((@N_TOTAL_AMOUNT - @N_PAID_AMOUNT) * @N_SELL_RATE, @nCurrDigits), 
   --open_payb_count = open_payb_count + 1 
   --where id = @N_VENDOR_ID  
   --rsd108661.180
   IF NOT EXISTS ( SELECT VENDOR_ID FROM VENDOR_ENTITY WHERE vendor_id = @N_VENDOR_ID and entity_id = @sEntityID )
     INSERT INTO VENDOR_ENTITY ( VENDOR_ID, ENTITY_ID ) VALUES ( @N_VENDOR_ID, @sEntityID ) 
   update VENDOR_ENTITY set 
   total_open_payb = total_open_payb + ROUND((@N_TOTAL_AMOUNT - @N_PAID_AMOUNT) * @N_SELL_RATE, @nCurrDigits), 
   open_payb_count = open_payb_count + 1  
   where vendor_id = @N_VENDOR_ID and entity_id = @sEntityID 
 END  
 select @bDoAdjust = 0  
 if (@N_PAY_STATUS = 'X') and (@N_PAY_STATUS != @O_PAY_STATUS) and (@O_PAY_STATUS != 'L')  
  select @bDoAdjust = 1  
 if ((@N_PAY_STATUS = 'P') or (@N_PAY_STATUS = 'H')) and (@O_PAY_STATUS = 'L')  
  select @bDoAdjust = 1  
 if (@O_SELL_RATE != @N_SELL_RATE) and (@O_PAY_STATUS != 'L')  
  select @bDoAdjust = 1  
 if @bDoAdjust = 1  
  BEGIN  
  If @O_SELL_RATE = 0  
   SELECT @O_SELL_RATE = 1  
  If @N_SELL_RATE = 0  
   SELECT @N_SELL_RATE = 1  
  DECLARE PAYABLE_UPD2 CURSOR LOCAL FOR  
  select workorder_type, workorder_base_id, workorder_lot_id, workorder_split_id, cost_category, amount, fixed_Charge  
  from PAYABLE_LINE  
  where voucher_id = @N_VOUCHER_ID and workorder_base_id is not null  
  OPEN PAYABLE_UPD2  
  FETCH PAYABLE_UPD2 INTO  
  @WORKORDER_TYPE, @WORKORDER_BASE_ID, @WORKORDER_LOT_ID, @WORKORDER_SPLIT_ID, @COST_CATEGORY, @AMOUNT, @FIXED_Charge  
  WHILE ( @nRcd = 0 and @@FETCH_STATUS <> -1 )  
   BEGIN  
   SELECT @MATL_COST = 0  
   SELECT @SERV_COST = 0  
   --sld636813 Round nCost calculation
   IF @N_PAY_STATUS = 'X'  
    SELECT @nCost = ROUND((( @AMOUNT + @FIXED_Charge ) * @N_SELL_RATE * -1),2)
   ELSE  
    SELECT @nCost = ROUND(( @AMOUNT + @FIXED_Charge ) * ( @N_SELL_RATE - @O_SELL_RATE ),2)  
   if @COST_CATEGORY = 'M'  
   SELECT @MATL_COST = @nCost  
   if @COST_CATEGORY = 'S'  
    SELECT @SERV_COST = @nCost  
   update WORK_ORDER set act_material_cost = act_material_cost + @MATL_COST, act_service_cost = act_service_cost + @SERV_COST, posting_candidate = 'Y'  
   where type = @WORKORDER_TYPE and base_id = @WORKORDER_BASE_ID and lot_id = @WORKORDER_LOT_ID and split_id = @WORKORDER_SPLIT_ID and sub_id = '0'  
   FETCH PAYABLE_UPD2 INTO  
   @WORKORDER_TYPE, @WORKORDER_BASE_ID, @WORKORDER_LOT_ID, @WORKORDER_SPLIT_ID, @COST_CATEGORY, @AMOUNT, @FIXED_Charge  
   END  
  DEALLOCATE PAYABLE_UPD2  
  END  
 END  
 IF @N_PAY_STATUS != @O_PAY_STATUS  
 update payable set status_eff_date = GetDate() where VOUCHER_ID = @N_VOUCHER_ID  
 IF @nRcd = 0  
 FETCH PAYABLE_UPD INTO  
 @N_VOUCHER_ID, @N_PAY_STATUS, @N_VENDOR_ID, @N_TOTAL_AMOUNT, @N_PAID_AMOUNT, @N_LAST_PAID_DATE, @N_SELL_RATE, @N_SITE_ID, 
 @O_VOUCHER_ID, @O_PAY_STATUS, @O_VENDOR_ID, @O_TOTAL_AMOUNT, @O_PAID_AMOUNT, @O_SELL_RATE  
END  
DEALLOCATE PAYABLE_UPD  
END  
IF (@nRcd <> 0) RAISERROR('VMFG-%d error in trigger UPDATE_PAYABLE', 16, -1, @nRcd)  
IF (@nRcd <> 0 Or @@ERROR <> 0) ROLLBACK TRANSACTION
GO

ALTER TABLE [dbo].[PAYABLE] ENABLE TRIGGER [UPDATE_PAYABLE]
GO


