unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinsDefaultPainters,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  dxDateRanges, Data.DB, cxDBData, cxContainer, Vcl.ComCtrls, dxCore,
  cxDateUtils, Vcl.StdCtrls, Vcl.ExtCtrls, cxDropDownEdit, cxCalendar,
  cxTextEdit, cxMaskEdit, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, Ora, dxmdaset, DBAccess, MemDS,
  OraCall, cxCheckBox, cxCheckComboBox, cxSpinEdit, Math,
  System.Generics.Collections;

type
  TForm1 = class(TForm)
    cxGrid1DBTableView1: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    cxDateEdit1: TcxDateEdit;
    Panel1: TPanel;
    btnLoad: TButton;
    btnSave: TButton;
    btnCancel: TButton;
    OraSession1: TOraSession;
    OraStoredProc1: TOraStoredProc;
    OraDataSource1: TOraDataSource;
    dxMemData1: TdxMemData;
    dxMemData1BATCH_ID: TFloatField;
    dxMemData1BARCODE: TStringField;
    dxMemData1PRODUCT_NAME: TStringField;
    dxMemData1CATEGORY_NAME: TStringField;
    dxMemData1QTY: TFloatField;
    dxMemData1BASE_PRICE: TFloatField;
    dxMemData1EXPIRY_DATE: TDateTimeField;
    dxMemData1DAYS_LEFT: TFloatField;
    dxMemData1DISCOUNT_PERCENT: TFloatField;
    dxMemData1FINAL_PRICE: TFloatField;
    dxMemData1IS_WRITE_OFF: TIntegerField;
    cxGrid1DBTableView1RecId: TcxGridDBColumn;
    cxGrid1DBTableView1BATCH_ID: TcxGridDBColumn;
    cxGrid1DBTableView1BARCODE: TcxGridDBColumn;
    cxGrid1DBTableView1PRODUCT_NAME: TcxGridDBColumn;
    cxGrid1DBTableView1CATEGORY_NAME: TcxGridDBColumn;
    cxGrid1DBTableView1QTY: TcxGridDBColumn;
    cxGrid1DBTableView1BASE_PRICE: TcxGridDBColumn;
    cxGrid1DBTableView1EXPIRY_DATE: TcxGridDBColumn;
    cxGrid1DBTableView1DAYS_LEFT: TcxGridDBColumn;
    cxGrid1DBTableView1DISCOUNT_PERCENT: TcxGridDBColumn;
    cxGrid1DBTableView1FINAL_PRICE: TcxGridDBColumn;
    cxGrid1DBTableView1IS_WRITE_OFF: TcxGridDBColumn;
    cxCheckComboBox1: TcxCheckComboBox;
    cxCheckComboBox2: TcxCheckComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure cxGrid1DBTableView1Editing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure cxGrid1DBTableView1CustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure dxMemData1BeforePost(DataSet: TDataSet);
    procedure cxGrid1DBTableView1IS_WRITE_OFFPropertiesEditValueChanged(
      Sender: TObject);
    procedure cxGrid1DBTableView1DISCOUNT_PERCENTPropertiesEditValueChanged(
      Sender: TObject);
    procedure cxGrid1DBTableView1EXPIRY_DATEPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cxGrid1DBTableView1DataControllerSummaryAfterSummary(
      ASender: TcxDataSummary);
    procedure cxCheckComboBox2PropertiesEditValueChanged(Sender: TObject);
  private
    FOrigDiscount: TDictionary<Integer, Double>;
    FOrigWriteOff: TDictionary<Integer, Integer>;
    procedure SetupFooterSummaries;
    procedure RecalcFooterSummaries;
    procedure SnapshotOriginals;
    function OdciNumberListLiteral(const AValues: TArray<Double>): string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnCancelClick(Sender: TObject);
begin
  if cxGrid1DBTableView1.Controller.IsEditing then
    cxGrid1DBTableView1.Controller.EditingController.HideEdit(False);

  if dxMemData1.Active and (dxMemData1.State in [dsEdit, dsInsert]) then
    dxMemData1.Cancel;

  btnLoadClick(Sender);
  cxGrid1DBTableView1.Invalidate(True);
end;

procedure TForm1.btnLoadClick(Sender: TObject);
var
  i: Integer;
  FieldName: string;
  SelectedIDs: string;
begin
  SelectedIDs := '';
  for i := 0 to cxCheckComboBox1.Properties.Items.Count - 1 do
  begin
    if cxCheckComboBox1.States[i] = cbsChecked then
    begin
      if SelectedIDs <> '' then
        SelectedIDs := SelectedIDs + ',';
      SelectedIDs := SelectedIDs + IntToStr(cxCheckComboBox1.Properties.Items[i].Tag);
    end;
  end;

  OraStoredProc1.Close;
  OraStoredProc1.StoredProcName := 'PKG_EXPIRY_CONTROL.GET_BATCHES';
  OraStoredProc1.Prepare;
  OraStoredProc1.ParamByName('p_date').AsDate := cxDateEdit1.Date;

  if SelectedIDs = '' then
    OraStoredProc1.ParamByName('p_category_ids').Clear
  else
    OraStoredProc1.ParamByName('p_category_ids').AsString := SelectedIDs;

  OraStoredProc1.Open;

  dxMemData1.DisableControls;
  try
    dxMemData1.Close;
    dxMemData1.Open;

    while not dxMemData1.IsEmpty do
      dxMemData1.Delete;

    dxMemData1.CopyFromDataSet(OraStoredProc1);
    SnapshotOriginals;
    if not dxMemData1.IsEmpty then
      dxMemData1.First;
  finally
    dxMemData1.EnableControls;
  end;

  OraStoredProc1.Close;

  if cxGrid1DBTableView1.ColumnCount = 0 then
  begin
    cxGrid1DBTableView1.DataController.CreateAllItems;

    for i := 0 to cxGrid1DBTableView1.ColumnCount - 1 do
    begin
      FieldName := cxGrid1DBTableView1.Columns[i].DataBinding.FieldName;
      cxGrid1DBTableView1.Columns[i].Options.Editing :=
        (FieldName = 'DISCOUNT_PERCENT') or (FieldName = 'IS_WRITE_OFF');
    end;
  end;

  RecalcFooterSummaries;
end;


procedure TForm1.btnSaveClick(Sender: TObject);
var
  SaveSQL: TOraSQL;
  Ids, Discounts, WriteOffs: TArray<Double>;
  Cap, N, BatchId, WriteOff, OrigWO: Integer;
  Discount, OrigDisc: Double;
  NeedSave: Boolean;
begin
  if not dxMemData1.Active or dxMemData1.IsEmpty then Exit;

  if cxGrid1DBTableView1.Controller.IsEditing then
    cxGrid1DBTableView1.DataController.Post;

  if dxMemData1.State in [dsEdit, dsInsert] then
    dxMemData1.Post;

  Cap := dxMemData1.RecordCount;
  SetLength(Ids, Cap);
  SetLength(Discounts, Cap);
  SetLength(WriteOffs, Cap);
  N := 0;

  dxMemData1.DisableControls;
  try
    dxMemData1.First;
    while not dxMemData1.Eof do
    begin
      BatchId := dxMemData1.FieldByName('BATCH_ID').AsInteger;
      Discount := dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat;
      WriteOff := dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger;

      NeedSave := True;
      if (FOrigDiscount <> nil) and (FOrigWriteOff <> nil) and
         FOrigDiscount.TryGetValue(BatchId, OrigDisc) and
         FOrigWriteOff.TryGetValue(BatchId, OrigWO) then
        NeedSave := (not SameValue(Discount, OrigDisc, 1E-6)) or (WriteOff <> OrigWO);

      if NeedSave then
      begin
        Ids[N] := BatchId;
        Discounts[N] := Discount;
        WriteOffs[N] := WriteOff;
        Inc(N);
      end;

      dxMemData1.Next;
    end;
  finally
    dxMemData1.EnableControls;
  end;

  if N = 0 then
  begin
    ShowMessage('Немає змін для збереження.');
    Exit;
  end;

  SetLength(Ids, N);
  SetLength(Discounts, N);
  SetLength(WriteOffs, N);

  // Один мережевий виклик. Літерали ODCINUMBERLIST надійні в ODAC Direct mode
  // (bind nested table через AsTable там дає AV / nil).
  SaveSQL := TOraSQL.Create(nil);
  try
    SaveSQL.Session := OraSession1;
    SaveSQL.SQL.Text :=
      'BEGIN PKG_EXPIRY_CONTROL.SAVE_BATCHES_BULK(' +
      OdciNumberListLiteral(Ids) + ', ' +
      OdciNumberListLiteral(Discounts) + ', ' +
      OdciNumberListLiteral(WriteOffs) + '); END;';

    OraSession1.StartTransaction;
    try
      SaveSQL.Execute;
      OraSession1.Commit;
      ShowMessage(Format('Дані успішно збережено! (%d записів)', [N]));
    except
      on E: Exception do
      begin
        OraSession1.Rollback;
        ShowMessage('Помилка при збереженні: ' + E.Message);
        Exit;
      end;
    end;
  finally
    SaveSQL.Free;
  end;

  btnLoadClick(Sender);
end;

procedure TForm1.cxCheckComboBox2PropertiesEditValueChanged(Sender: TObject);
var
  DaysCol, WriteOffCol: TcxGridDBColumn;
  CriticalGroup: TcxFilterCriteriaItemList;
  HasSelectedFilters: Boolean;
begin
  DaysCol := cxGrid1DBTableView1DAYS_LEFT;
  WriteOffCol := cxGrid1DBTableView1IS_WRITE_OFF;

  with cxGrid1DBTableView1.DataController.Filter do
  begin
    BeginUpdate;
    try
      Root.Clear;
      // Если выбрано несколько пунктов — объединяем их через логическое ИЛИ (OR)
      Root.BoolOperatorKind := fboOr;

      HasSelectedFilters := False;

      // 0: Тільки прострочені (DAYS_LEFT < 0)
      if cxCheckComboBox2.States[0] = cbsChecked then
      begin
        Root.AddItem(DaysCol, foLess, 0, '< 0');
        HasSelectedFilters := True;
      end;

      // 1: Тільки критичні (0 <= DAYS_LEFT <= 2 и товар еще не списан)
      if cxCheckComboBox2.States[1] = cbsChecked then
      begin
        // Создаем подгруппу с условием И (AND): (0 <= DAYS_LEFT <= 2) AND (IS_WRITE_OFF = 0)
        CriticalGroup := Root.AddItemList(fboAnd);
        CriticalGroup.AddItem(DaysCol, foGreaterEqual, 0, '>= 0');
        CriticalGroup.AddItem(DaysCol, foLessEqual, 2, '<= 2');
        CriticalGroup.AddItem(WriteOffCol, foEqual, 0, '0');
        HasSelectedFilters := True;
      end;

      // 2: Тільки до списання (IS_WRITE_OFF = 1)
      if cxCheckComboBox2.States[2] = cbsChecked then
      begin
        Root.AddItem(WriteOffCol, foEqual, 1, '1');
        HasSelectedFilters := True;
      end;

      // Если ни один чекбокс не выбран — фильтр выключен (показываем все строки)
      Active := HasSelectedFilters;
    finally
      EndUpdate;
    end;
  end;

  // Автоматический пересчет финансовых итогов в подвале под видимые строки
  RecalcFooterSummaries;
end;

procedure TForm1.cxGrid1DBTableView1CustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  ColDaysLeft, ColWriteOff: TcxGridDBColumn;
  DaysLeftVal, WriteOffVal: Variant;
  IsExpiredOrWriteOff: Boolean;
begin
  ColDaysLeft := cxGrid1DBTableView1.GetColumnByFieldName('DAYS_LEFT');
  ColWriteOff := cxGrid1DBTableView1.GetColumnByFieldName('IS_WRITE_OFF');

  if (ColDaysLeft = nil) or (ColWriteOff = nil) then Exit;

  DaysLeftVal := AViewInfo.GridRecord.Values[ColDaysLeft.Index];
  WriteOffVal := AViewInfo.GridRecord.Values[ColWriteOff.Index];

  IsExpiredOrWriteOff := False;

  if not VarIsNull(DaysLeftVal) and (Integer(DaysLeftVal) < 0) then
    IsExpiredOrWriteOff := True;

  if not VarIsNull(WriteOffVal) and (Integer(WriteOffVal) = 1) then
    IsExpiredOrWriteOff := True;

  if IsExpiredOrWriteOff then
  begin
    ACanvas.Brush.Color := $00C0C0FF;
    ACanvas.Font.Color  := clMaroon;
    ACanvas.Font.Style  := [fsBold];
  end
  else if not VarIsNull(DaysLeftVal) and (Integer(DaysLeftVal) >= 0) and (Integer(DaysLeftVal) <= 2) then
  begin
    ACanvas.Brush.Color := $00C8FFFF;
    ACanvas.Font.Color  := clBlack;
    ACanvas.Font.Style  := [];
  end;
end;

procedure TForm1.cxGrid1DBTableView1DISCOUNT_PERCENTPropertiesEditValueChanged(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
  Discount, BasePrice: Double;
begin
  Edit := Sender as TcxCustomEdit;
  Edit.PostEditValue;

  if VarIsNull(Edit.EditValue) then Exit;

  Discount := Double(Edit.EditValue);

  if Discount < 0 then Discount := 0;
  if Discount > 90 then Discount := 90;

  BasePrice := dxMemData1.FieldByName('BASE_PRICE').AsFloat;

  dxMemData1.Edit;
  dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat := Discount;
  dxMemData1.FieldByName('FINAL_PRICE').AsFloat := SimpleRoundTo(BasePrice * (1.0 - (Discount / 100.0)), -2);
  dxMemData1.Post;
  RecalcFooterSummaries;
end;

procedure TForm1.cxGrid1DBTableView1Editing(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
var
  DaysLeft, IsWriteOff: Integer;
  FieldName: string;
begin
  FieldName := TcxGridDBColumn(AItem).DataBinding.FieldName;

  DaysLeft := dxMemData1.FieldByName('DAYS_LEFT').AsInteger;
  IsWriteOff := dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger;

  if cxDateEdit1.Date < Date then
  begin
    AAllow := False;
    Exit;
  end;

  if DaysLeft < 0 then
  begin
    if FieldName <> 'IS_WRITE_OFF' then
      AAllow := False;
    Exit;
  end;

  if (DaysLeft > 2) and (FieldName = 'DISCOUNT_PERCENT') then
  begin
    AAllow := False;
    Exit;
  end;

  if (IsWriteOff = 1) and (FieldName = 'DISCOUNT_PERCENT') then
    AAllow := False;
end;


procedure TForm1.cxGrid1DBTableView1EXPIRY_DATEPropertiesEditValueChanged(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
  NewExpiryDate, ControlDate: TDateTime;
  NewDaysLeft: Integer;
begin
  Edit := Sender as TcxCustomEdit;
  Edit.PostEditValue;

  if VarIsNull(Edit.EditValue) then Exit;

  NewExpiryDate := Trunc(VarToDateTime(Edit.EditValue));
  ControlDate   := Trunc(cxDateEdit1.Date);

  NewDaysLeft := Trunc(NewExpiryDate) - Trunc(ControlDate);

  dxMemData1.Edit;
  dxMemData1.FieldByName('EXPIRY_DATE').AsDateTime := NewExpiryDate;
  dxMemData1.FieldByName('DAYS_LEFT').AsInteger   := NewDaysLeft;

  if NewDaysLeft < 0 then
  begin
    dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger := 1;
    dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat := 0.0;
    dxMemData1.FieldByName('FINAL_PRICE').AsFloat := 0.0;
  end;

  dxMemData1.Post;

  cxGrid1DBTableView1.Invalidate(False);
  RecalcFooterSummaries;
end;

procedure TForm1.cxGrid1DBTableView1IS_WRITE_OFFPropertiesEditValueChanged(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
  NewVal: Integer;
begin
  Edit := Sender as TcxCustomEdit;
  Edit.PostEditValue;

  if VarIsNull(Edit.EditValue) then
    NewVal := 0
  else
    NewVal := Integer(Edit.EditValue);

  dxMemData1.Edit;
  dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger := NewVal;

  if NewVal = 1 then
  begin
    dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat := 0;
    dxMemData1.FieldByName('FINAL_PRICE').AsFloat := 0;
  end
  else
  begin
    dxMemData1.FieldByName('FINAL_PRICE').AsFloat := dxMemData1.FieldByName('BASE_PRICE').AsFloat;
  end;
  dxMemData1.Post;

  cxGrid1DBTableView1.Invalidate(False);
  RecalcFooterSummaries;
end;

procedure TForm1.cxGrid1DBTableView1DataControllerSummaryAfterSummary(
  ASender: TcxDataSummary);
var
  I, RecIdx, ItemIdx: Integer;
  RevenueSum, WriteOffSum: Double;
  Qty, FinalPrice, BasePrice, IsWriteOff: Variant;
  ColQty, ColFinal, ColBase, ColWO: Integer;
  Item: TcxGridDBTableSummaryItem;
begin
  ColQty := cxGrid1DBTableView1QTY.Index;
  ColFinal := cxGrid1DBTableView1FINAL_PRICE.Index;
  ColBase := cxGrid1DBTableView1BASE_PRICE.Index;
  ColWO := cxGrid1DBTableView1IS_WRITE_OFF.Index;

  RevenueSum := 0;
  WriteOffSum := 0;

  for I := 0 to ASender.DataController.FilteredRecordCount - 1 do
  begin
    RecIdx := ASender.DataController.FilteredRecordIndex[I];

    Qty := ASender.DataController.Values[RecIdx, ColQty];
    FinalPrice := ASender.DataController.Values[RecIdx, ColFinal];
    BasePrice := ASender.DataController.Values[RecIdx, ColBase];
    IsWriteOff := ASender.DataController.Values[RecIdx, ColWO];

    // Revenue after markdown: QTY * FINAL_PRICE
    if not VarIsNull(Qty) and not VarIsNull(FinalPrice) then
      RevenueSum := RevenueSum + Double(Qty) * Double(FinalPrice);

    // Write-off cost: QTY * BASE_PRICE when IS_WRITE_OFF = 1
    if not VarIsNull(IsWriteOff) and (Integer(IsWriteOff) = 1) then
      if not VarIsNull(Qty) and not VarIsNull(BasePrice) then
        WriteOffSum := WriteOffSum + Double(Qty) * Double(BasePrice);
  end;

  for ItemIdx := 0 to ASender.FooterSummaryItems.Count - 1 do
  begin
    Item := ASender.FooterSummaryItems[ItemIdx] as TcxGridDBTableSummaryItem;
    if Item.Column = cxGrid1DBTableView1FINAL_PRICE then
      ASender.FooterSummaryValues[ItemIdx] := SimpleRoundTo(RevenueSum, -2)
    else if Item.Column = cxGrid1DBTableView1IS_WRITE_OFF then
      ASender.FooterSummaryValues[ItemIdx] := SimpleRoundTo(WriteOffSum, -2);
  end;
end;

procedure TForm1.SetupFooterSummaries;
begin
  cxGrid1DBTableView1.OptionsView.Footer := True;
  cxGrid1DBTableView1.DataController.Summary.OnAfterSummary :=
    cxGrid1DBTableView1DataControllerSummaryAfterSummary;

  with cxGrid1DBTableView1.DataController.Summary do
  begin
    BeginUpdate;
    try
      FooterSummaryItems.Clear;

      // PRODUCT_NAME — count of positions
      with FooterSummaryItems.Add as TcxGridDBTableSummaryItem do
      begin
        Column := cxGrid1DBTableView1PRODUCT_NAME;
        Kind := skCount;
        Format := '0';
      end;

      // QTY — total stock
      with FooterSummaryItems.Add as TcxGridDBTableSummaryItem do
      begin
        Column := cxGrid1DBTableView1QTY;
        Kind := skSum;
        Format := ',0.##';
      end;

      // FINAL_PRICE — QTY * FINAL_PRICE (custom in OnAfterSummary)
      with FooterSummaryItems.Add as TcxGridDBTableSummaryItem do
      begin
        Column := cxGrid1DBTableView1FINAL_PRICE;
        Kind := skSum;
        Format := 'Виручка: ,0.00';
      end;

      // IS_WRITE_OFF — QTY * BASE_PRICE for write-offs (custom in OnAfterSummary)
      with FooterSummaryItems.Add as TcxGridDBTableSummaryItem do
      begin
        Column := cxGrid1DBTableView1IS_WRITE_OFF;
        Kind := skSum;
        Format := 'Списання: ,0.00';
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TForm1.RecalcFooterSummaries;
begin
  if cxGrid1DBTableView1.OptionsView.Footer then
    cxGrid1DBTableView1.DataController.Summary.Recalculate;
end;

procedure TForm1.dxMemData1BeforePost(DataSet: TDataSet);
var
  BasePrice, Discount: Double;
begin
  BasePrice := DataSet.FieldByName('BASE_PRICE').AsFloat;
  Discount := DataSet.FieldByName('DISCOUNT_PERCENT').AsFloat;

  if Discount < 0.0 then
    Discount := 0.0
  else if Discount > 90.0 then
    Discount := 90.0;

  if DataSet.FieldByName('IS_WRITE_OFF').AsInteger = 1 then
  begin
    DataSet.FieldByName('DISCOUNT_PERCENT').AsFloat := 0.0;
    DataSet.FieldByName('FINAL_PRICE').AsFloat := 0.0;
  end
  else
  begin
    DataSet.FieldByName('DISCOUNT_PERCENT').AsFloat := Discount;
    DataSet.FieldByName('FINAL_PRICE').AsFloat :=
      SimpleRoundTo(BasePrice * (1.0 - (Discount / 100.0)), -2);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Q: TOraQuery;
begin
  FOrigDiscount := TDictionary<Integer, Double>.Create;
  FOrigWriteOff := TDictionary<Integer, Integer>.Create;

  cxDateEdit1.Date := Date;
  SetupFooterSummaries;

  Q := TOraQuery.Create(nil);
  try
    Q.Session := OraSession1;
    Q.SQL.Text := 'SELECT id, name FROM ref_categories WHERE status = 1 ORDER BY name';
    Q.Open;

    cxCheckComboBox1.Properties.Items.Clear;
    while not Q.Eof do
    begin
      with cxCheckComboBox1.Properties.Items.Add do
      begin
        Description := Q.FieldByName('name').AsString;
        Tag := Q.FieldByName('id').AsInteger;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FOrigDiscount);
  FreeAndNil(FOrigWriteOff);
end;

procedure TForm1.SnapshotOriginals;
var
  BatchId: Integer;
begin
  FOrigDiscount.Clear;
  FOrigWriteOff.Clear;

  if not dxMemData1.Active then Exit;

  dxMemData1.First;
  while not dxMemData1.Eof do
  begin
    BatchId := dxMemData1.FieldByName('BATCH_ID').AsInteger;
    FOrigDiscount.AddOrSetValue(BatchId, dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat);
    FOrigWriteOff.AddOrSetValue(BatchId, dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger);
    dxMemData1.Next;
  end;
end;

function TForm1.OdciNumberListLiteral(const AValues: TArray<Double>): string;
var
  I: Integer;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := #0;

  Result := 'SYS.ODCINUMBERLIST(';
  for I := 0 to High(AValues) do
  begin
    if I > 0 then
      Result := Result + ',';
    Result := Result + FloatToStr(AValues[I], FS);
  end;
  Result := Result + ')';
end;

end.
