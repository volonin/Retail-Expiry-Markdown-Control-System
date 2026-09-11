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
  OraCall, cxCheckBox, cxCheckComboBox, cxSpinEdit, Math;

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
    procedure FormCreate(Sender: TObject);
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
  private
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
  // 1. Отменяем и скрываем активный редактор в ячейке грида
  if cxGrid1DBTableView1.Controller.IsEditing then
    cxGrid1DBTableView1.Controller.EditingController.HideEdit(False);

  // 2. Отменяем изменения на уровне буфера датасета
  if dxMemData1.Active and (dxMemData1.State in [dsEdit, dsInsert]) then
    dxMemData1.Cancel;

  // 3. Заново загружаем чистые данные из базы
  btnLoadClick(Sender);

  // 4. Перерисовываем представление
  cxGrid1DBTableView1.Invalidate(True);
end;

procedure TForm1.btnLoadClick(Sender: TObject);
var
  i: Integer;
  FieldName: string;
  SelectedIDs: string;
begin
  // 1. Собираем ID отмеченных категорий
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

  // 2. Настраиваем и выполняем процедуру
  OraStoredProc1.Close;
  OraStoredProc1.StoredProcName := 'PKG_EXPIRY_CONTROL.GET_BATCHES';
  OraStoredProc1.Prepare;
  OraStoredProc1.ParamByName('p_date').AsDate := cxDateEdit1.Date;

  // Если ничего не выбрано — передаем NULL (выборка всех категорий)
  if SelectedIDs = '' then
    OraStoredProc1.ParamByName('p_category_ids').Clear
  else
    OraStoredProc1.ParamByName('p_category_ids').AsString := SelectedIDs;

  OraStoredProc1.Open;

  // 3. Очищаем TdxMemData и копируем новые строки
  dxMemData1.DisableControls;
  try
    dxMemData1.Close;
    dxMemData1.Open;

    while not dxMemData1.IsEmpty do
      dxMemData1.Delete;

    dxMemData1.CopyFromDataSet(OraStoredProc1);
  finally
    dxMemData1.EnableControls;
  end;

  OraStoredProc1.Close;

  // 4. Построение колонок грида при первом запуске
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
end;


procedure TForm1.btnSaveClick(Sender: TObject);
var
  SaveProc: TOraStoredProc;
begin
  if not dxMemData1.Active or dxMemData1.IsEmpty then Exit;

  // 1. Завершаем активный ввод в ячейке грида, если курсор остался там
  if cxGrid1DBTableView1.Controller.IsEditing then
    cxGrid1DBTableView1.DataController.Post;

  // 2. Завершаем редактирование на уровне датасета
  if dxMemData1.State in [dsEdit, dsInsert] then
    dxMemData1.Post;

  // 3. Создаем процедуру сохранения
  SaveProc := TOraStoredProc.Create(nil);
  try
    SaveProc.Session := OraSession1;
    SaveProc.StoredProcName := 'PKG_EXPIRY_CONTROL.SAVE_BATCH';
    SaveProc.Prepare;

    // 4. Открываем транзакцию
    OraSession1.StartTransaction;
    try
      dxMemData1.DisableControls; // Отключаем UI для максимальной скорости
      try
        dxMemData1.First;
        while not dxMemData1.Eof do
        begin
          // Передаем параметры текущей партии
          SaveProc.ParamByName('p_batch_id').AsInteger := dxMemData1.FieldByName('BATCH_ID').AsInteger;
          SaveProc.ParamByName('p_discount_percent').AsFloat := dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat;
          SaveProc.ParamByName('p_is_write_off').AsInteger := dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger;

          // Если меняли дату срока годности
          if SaveProc.FindParam('p_expiry_date') <> nil then
            SaveProc.ParamByName('p_expiry_date').AsDate := dxMemData1.FieldByName('EXPIRY_DATE').AsDateTime;

          SaveProc.Execute;

          dxMemData1.Next;
        end;
      finally
        dxMemData1.EnableControls;
      end;

      // 5. Фиксируем изменения в базе
      OraSession1.Commit;
      ShowMessage('Дані успішно збережено!');

    except
      on E: Exception do
      begin
        // Откатываем транзакцию в случае сбоя
        OraSession1.Rollback;
        ShowMessage('Помилка при збереженні: ' + E.Message);
        Exit;
      end;
    end;
  finally
    SaveProc.Free;
  end;

  // 6. Перечитываем свежие данные из базы и обновляем подсветку
  btnLoadClick(Sender);
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

  // Проверяем: либо дни ушли в минус, либо включен флаг списания (1)
  IsExpiredOrWriteOff := False;

  if not VarIsNull(DaysLeftVal) and (Integer(DaysLeftVal) < 0) then
    IsExpiredOrWriteOff := True;

  if not VarIsNull(WriteOffVal) and (Integer(WriteOffVal) = 1) then
    IsExpiredOrWriteOff := True;

  // 1. КРАСНЫЙ: Просрочено или Списание
  if IsExpiredOrWriteOff then
  begin
    ACanvas.Brush.Color := $00C0C0FF; // Мягкий пастельный красный (BGR)
    ACanvas.Font.Color  := clMaroon;  // Тёмно-красный текст
    ACanvas.Font.Style  := [fsBold];
  end
  // 2. ЖЕЛТЫЙ: Критический срок (0..2 дня) и еще не списан
  else if not VarIsNull(DaysLeftVal) and (Integer(DaysLeftVal) >= 0) and (Integer(DaysLeftVal) <= 2) then
  begin
    ACanvas.Brush.Color := $00C8FFFF; // Мягкий пастельный желтый (BGR)
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

  // Валидация прямо на лету
  if Discount < 0 then Discount := 0;
  if Discount > 90 then Discount := 90;

  BasePrice := dxMemData1.FieldByName('BASE_PRICE').AsFloat;

  dxMemData1.Edit;
  dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat := Discount;
  dxMemData1.FieldByName('FINAL_PRICE').AsFloat := SimpleRoundTo(BasePrice * (1.0 - (Discount / 100.0)), -2);
  dxMemData1.Post;
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

  // 1. Если дата контроля в прошлом — полный запрет правок
  if cxDateEdit1.Date < Date then
  begin
    AAllow := False;
    Exit;
  end;

  // 2. Если товар уже просрочен (DAYS_LEFT < 0)
  if DaysLeft < 0 then
  begin
    // Разрешаем менять только чекбокс списания
    if FieldName <> 'IS_WRITE_OFF' then
      AAllow := False;
    Exit;
  end;

  // 3. Если срок еще в норме (> 2 дней) — уценка не требуется
  if (DaysLeft > 2) and (FieldName = 'DISCOUNT_PERCENT') then
  begin
    AAllow := False;
    Exit;
  end;

  // 4. Если стоит галочка "Списание" — скидку менять нельзя
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
  // 1. Немедленно отдаем введенную дату из инплейс-редактора в грид
  Edit.PostEditValue;

  if VarIsNull(Edit.EditValue) then Exit;

  NewExpiryDate := Trunc(VarToDateTime(Edit.EditValue));
  ControlDate   := Trunc(cxDateEdit1.Date);

  // 2. Считаем новую разницу в днях
  NewDaysLeft := Trunc(NewExpiryDate) - Trunc(ControlDate);

  // 3. Записываем в датасет
  dxMemData1.Edit;
  dxMemData1.FieldByName('EXPIRY_DATE').AsDateTime := NewExpiryDate;
  dxMemData1.FieldByName('DAYS_LEFT').AsInteger   := NewDaysLeft;

  // Если дата ушла в прошлое относительно контроля — товар просрочен:
  // автоматически включаем списание и сбрасываем цену в 0
  if NewDaysLeft < 0 then
  begin
    dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger := 1;
    dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat := 0.0;
    dxMemData1.FieldByName('FINAL_PRICE').AsFloat := 0.0;
  end;

  dxMemData1.Post;

  // 4. Мгновенная перерисовка всей таблицы для обновления цвета
  cxGrid1DBTableView1.Invalidate(False);
end;

procedure TForm1.cxGrid1DBTableView1IS_WRITE_OFFPropertiesEditValueChanged(
  Sender: TObject);
var
  Edit: TcxCustomEdit;
  NewVal: Integer;
begin
  Edit := Sender as TcxCustomEdit;
  // 1. Немедленно отдаем введенное значение из редактора
  Edit.PostEditValue;

  if VarIsNull(Edit.EditValue) then
    NewVal := 0
  else
    NewVal := Integer(Edit.EditValue);

  // 2. Обновляем поля в dxMemData
  dxMemData1.Edit;
  dxMemData1.FieldByName('IS_WRITE_OFF').AsInteger := NewVal;

  if NewVal = 1 then
  begin
    // Если списано — обнуляем скидку и цену
    dxMemData1.FieldByName('DISCOUNT_PERCENT').AsFloat := 0;
    dxMemData1.FieldByName('FINAL_PRICE').AsFloat := 0;
  end
  else
  begin
    // Если галочку сняли — возвращаем базовую цену
    dxMemData1.FieldByName('FINAL_PRICE').AsFloat := dxMemData1.FieldByName('BASE_PRICE').AsFloat;
  end;
  dxMemData1.Post;

  // 3. ПРИНУДИТЕЛЬНО ПЕРЕРИСОВЫВАЕМ ГРИД
  cxGrid1DBTableView1.Invalidate(False);
end;

procedure TForm1.dxMemData1BeforePost(DataSet: TDataSet);
var
  BasePrice, Discount: Double;
begin
  BasePrice := DataSet.FieldByName('BASE_PRICE').AsFloat;
  Discount := DataSet.FieldByName('DISCOUNT_PERCENT').AsFloat;

  // Валидация диапазона
  if Discount < 0.0 then
    Discount := 0.0
  else if Discount > 90.0 then
    Discount := 90.0;

  // Применяем вычисленные значения
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
  cxDateEdit1.Date := Date;

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
        Tag := Q.FieldByName('id').AsInteger; // Сохраняем ID категории
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.
