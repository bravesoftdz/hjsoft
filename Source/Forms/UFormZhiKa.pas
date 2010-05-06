{*******************************************************************************
  作者: dmzn@163.com 2010-3-8
  描述: 纸卡办理
*******************************************************************************}
unit UFormZhiKa;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, dxLayoutControl, StdCtrls, cxControls, cxGraphics,
  ComCtrls, cxListView, cxDropDownEdit, cxTextEdit, cxContainer, cxEdit,
  cxMaskEdit, cxButtonEdit, cxLabel, Menus, cxCheckBox, cxCalendar;

type
  TfFormZhiKa = class(TfFormNormal)
    dxGroup2: TdxLayoutGroup;
    ListDetail: TcxListView;
    dxLayout1Item3: TdxLayoutItem;
    EditStock: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditPrice: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditValue: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    dxLayout1Group3: TdxLayoutGroup;
    EditCID: TcxButtonEdit;
    dxLayout1Item7: TdxLayoutItem;
    EditPName: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditSMan: TcxComboBox;
    dxLayout1Item9: TdxLayoutItem;
    EditCustom: TcxComboBox;
    dxLayout1Item10: TdxLayoutItem;
    EditLading: TcxComboBox;
    dxLayout1Item11: TdxLayoutItem;
    EditPayment: TcxComboBox;
    dxLayout1Item12: TdxLayoutItem;
    dxLayout1Group4: TdxLayoutGroup;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    EditMoney: TcxTextEdit;
    dxLayout1Item15: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    dxLayout1Item16: TdxLayoutItem;
    cxLabel2: TcxLabel;
    Check1: TcxCheckBox;
    dxLayout1Item17: TdxLayoutItem;
    EditDays: TcxDateEdit;
    dxLayout1Item18: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditSManPropertiesEditValueChanged(Sender: TObject);
    procedure EditCIDExit(Sender: TObject);
    procedure ListDetailClick(Sender: TObject);
    procedure EditPriceExit(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure EditCIDKeyPress(Sender: TObject; var Key: Char);
    procedure EditCIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnOKClick(Sender: TObject);
    procedure EditCustomKeyPress(Sender: TObject; var Key: Char);
  protected
    { Protected declarations }
    FRecordID: string;
    //记录编号
    FPrefixID: string;
    //前缀编号
    FIDLength: integer;
    //前缀长度
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
    //基类方法
    procedure InitFormData(const nID: string);
    //载入数据
    procedure LoadStockList;
    procedure LoadStockListSummary;
    //水泥列表
    procedure LoadSaleContract(const nCID: string);
    //载入合同
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, UMgrControl, UAdjustForm, UFormCtrl, UFormBase, UFrameBase,
  USysGrid, USysDB, USysConst, USysBusiness, UDataModule;

type
  TStockItem = record
   FType: string;
   FName: string;
   FPrice: Double;
   FValue: Double;
   FSelected: Boolean;
  end;

  TZhiKaItem = record
    FContract: string;
    FIsXuNi: Boolean;
    FIsValid: Boolean;
    
    FSaleMan: string;
    FSaleName: string;
    FSalePY: string;
    FCustomer: string;
    FCusName: string;
  end;

var
  gForm: TfFormZhiKa = nil;
  gZhiKa: TZhiKaItem;
  gStockList: array of TStockItem;

//------------------------------------------------------------------------------
class function TfFormZhiKa.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
    nD: TFormCommandParam;
begin
  Result := nil;
  nD.FCommand := cCmd_AddData;

  if Assigned(nParam) then
       nP := nParam
  else nP := @nD;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormZhiKa.Create(Application) do
    begin
      FRecordID := '';
      Caption := '纸卡 - 办理';

      InitFormData('');
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_EditData:
    with TfFormZhiKa.Create(Application) do
    begin
      FRecordID := nP.FParamA;
      Caption := '纸卡 - 修改';

      InitFormData(FRecordID);
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_ViewData:
    begin
      if not Assigned(gForm) then
      begin
        gForm := TfFormZhiKa.Create(Application);
        with gForm do
        begin
          FormStyle := fsStayOnTop; 
          BtnOK.Visible := False;
        end;
      end;

      with gForm  do
      begin
        FRecordID := nP.FParamA;
        Caption := '纸卡 - ' + FRecordID;
        
        InitFormData(FRecordID);
        if not Showing then Show;
      end;
    end;
   cCmd_FormClose:
    begin
      if Assigned(gForm) then FreeAndNil(gForm);
    end;
  end;
end;

class function TfFormZhiKa.FormID: integer;
begin
  Result := cFI_FormZhiKa;
end;

procedure TfFormZhiKa.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
    LoadcxListViewConfig(Name, ListDetail, nIni);

    FPrefixID := nIni.ReadString(Name, 'IDPrefix', 'ZK');
    FIDLength := nIni.ReadInteger(Name, 'IDLength', 8);
    Check1.Checked := nIni.ReadBool(Name, 'XianTi', False);
  finally
    nIni.Free;
  end;

  AdjustCtrlData(Self);
end;

procedure TfFormZhiKa.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveFormConfig(Self, nIni);
    SavecxListViewConfig(Name, ListDetail, nIni);
    nIni.WriteBool(Name, 'XianTi', Check1.Checked);
  finally
    nIni.Free;
  end;

  gForm := nil;
  Action := caFree;
  ReleaseCtrlData(Self);
end;

//------------------------------------------------------------------------------
//Desc: 纸卡编号
procedure TfFormZhiKa.InitFormData(const nID: string);
var nStr: string;
    nZK: TZhiKaItem;
    i,nIdx: integer;
    nDStr: TDynamicStrArray;
    nItem: array of TStockItem;
begin
  gZhiKa.FContract := '';
  gZhiKa.FIsValid := False;
  SetLength(gStockList, 0);
  
  if EditPayment.Properties.Items.Count < 1 then
  begin
    EditPayment.Clear;
    EditPayment.Text := '赊现';
    LoadSysDictItem(sFlag_PaymentItem, EditPayment.Properties.Items);
  end;

  if nID <> '' then
  begin
    nStr := 'Select zk.*,S_Name,S_PY,C_Name From $ZK zk ' +
            ' Left Join $SM sm On sm.S_ID=zk.Z_SaleMan' +
            ' Left Join $Cus cus On cus.c_ID=zk.Z_Custom ' +
            'Where Z_ID=''$ID''';
    nStr := MacroValue(nStr, [MI('$ZK', sTable_ZhiKa),
            MI('$Cus', sTable_Customer), MI('$SM', sTable_Salesman),
            MI('$ID', nID)]);
    //xxxxx

    with FDM.QuerySQL(nStr) do
    if RecordCount > 0 then
    begin
      with nZK do
      begin
        FContract := FieldByName('Z_CID').AsString;
        FSaleMan := FieldByName('Z_SaleMan').AsString;
        FSaleName := FieldByName('S_Name').AsString;
        FSalePY := FieldByName('S_PY').AsString;
        FCustomer := FieldByName('Z_Custom').AsString;
        FCusName := FieldByName('C_Name').AsString;
      end;

      SetLength(nDStr, 4);
      nDStr[0] := FieldByName('Z_Project').AsString;
      nDStr[1] := FieldByName('Z_Lading').AsString;
      nDStr[2] := FieldByName('Z_Payment').AsString;
      nDStr[3] := Date2Str(FieldByName('Z_ValidDays').AsDateTime);

      EditMoney.Text := FieldByName('Z_YFMoney').AsString;
      //预付金

      nStr := 'Select * From %s Where D_ZID=''%s''';
      nStr := Format(nStr, [sTable_ZhiKaDtl, nID]);

      with FDM.QueryTemp(nStr) do
      if RecordCount > 0 then
      begin
        SetLength(nItem, RecordCount);
        nIdx := 0;
        First;

        while not Eof do
        with nItem[nIdx] do
        begin
          FType := FieldByName('D_Type').AsString;
          FName := FieldByName('D_Stock').AsString;
          FPrice := FieldByName('D_Price').AsFloat;
          FValue := FieldByName('D_Value').AsFloat;

          Inc(nIdx);
          Next;
        end;
      end;

      LoadSaleContract(nZK.FContract);
      //读取合同

      if gZhiKa.FIsValid then
      begin
        gZhiKa.FSaleMan := nZK.FSaleMan;
        gZhiKa.FSaleName := nZK.FSaleName;
        gZhiKa.FSalePY := nZK.FSalePY;
        gZhiKa.FCustomer := nZK.FCustomer;
        gZhiKa.FCusName := nZK.FCusName;
      end else Exit;

      EditCID.Text := gZhiKa.FContract;
      EditPName.Text := nDStr[0];

      if gZhiKa.FIsXuNi then
      begin
        SetCtrlData(EditSMan, gZhiKa.FSaleMan);
        if GetStringsItemIndex(EditCustom.Properties.Items, gZhiKa.FCustomer) < 0 then
        begin
          nStr := Format('%s=%s.%s', [gZhiKa.FCustomer, gZhiKa.FCustomer,
                                      gZhiKa.FCusName]);
          InsertStringsItem(EditCustom.Properties.Items, nStr);
        end;
        SetCtrlData(EditCustom, gZhiKa.FCustomer);
      end else
      begin
        EditSMan.Text := Format('%s.%s', [gZhiKa.FSalePY, gZhiKa.FSaleName]);
        EditCustom.Text := Format('%s.%s', [gZhiKa.FCustomer, gZhiKa.FCusName]);
      end;

      SetCtrlData(EditLading, nDStr[1]);
      EditPayment.Text := nDStr[2];
      EditDays.Date := StrToDate(nDStr[3]);

      for nIdx:=Low(nItem) to High(nItem) do
      begin
        nStr := '';

        for i:=Low(gStockList) to High(gStockList) do
        if (gStockList[i].FType = nItem[nIdx].FType) and
           (gStockList[i].FName = nItem[nIdx].FName) then
        begin
          gStockList[i].FPrice := nItem[nIdx].FPrice;
          gStockList[i].FValue := nItem[nIdx].FValue;

          gStockList[i].FSelected := True;
          nStr := 'Y';
          Break;
        end;

        if nStr = '' then
        begin
          i := Length(gStockList);
          SetLength(gStockList, i + 1);

          gStockList[i].FType := nItem[nIdx].FType;
          gStockList[i].FName := nItem[nIdx].FName;
          gStockList[i].FPrice := nItem[nIdx].FPrice;
          gStockList[i].FValue := nItem[nIdx].FValue;
          gStockList[i].FSelected := True;
        end;
      end;
    end;

    LoadStockList;
    LoadStockListSummary;
  end;
end;

//Desc: 载入水泥列表
procedure TfFormZhiKa.LoadStockList;
var nIdx,nItem: integer;
begin
  nItem := ListDetail.ItemIndex;
  ListDetail.Items.BeginUpdate;
  try
    ListDetail.Items.Clear;

    for nIdx:=Low(gStockList) to High(gStockList) do
     with ListDetail.Items.Add do
     begin
       Caption := gStockList[nIdx].FName;
       SubItems.Add(Format('%.2f', [gStockList[nIdx].FPrice]));
       SubItems.Add(Format('%.2f', [gStockList[nIdx].FValue]));
       Checked := gStockList[nIdx].FSelected;
     end;
  finally
    ListDetail.Items.EndUpdate;
    ListDetail.ItemIndex := nItem;
  end;
end;

//Desc: 载入摘要
procedure TfFormZhiKa.LoadStockListSummary;
var nMoney: Double;
    nIdx,nNum: integer;
begin
  nNum := 0;
  nMoney := 0;
  dxGroup2.Caption := '办理明细';

  for nIdx:=Low(gStockList) to High(gStockList) do
  if gStockList[nIdx].FSelected then
  begin
    Inc(nNum);
    nMoney := nMoney + gStockList[nIdx].FPrice * gStockList[nIdx].FValue;
  end;

  if nNum > 0 then
    dxGroup2.Caption := dxGroup2.Caption +
      Format(' 已选:[ %d ]种 总额:[ %.2f ]元', [nNum, nMoney]);
  //xxxxx
end;

//Desc: 载入编号为nCID的合同到窗体
procedure TfFormZhiKa.LoadSaleContract(const nCID: string);
var nStr: string;
    nIdx: integer;
begin
  if CompareText(nCID, gZhiKa.FContract) = 0 then
       Exit
  else gZhiKa.FIsValid := False;
  
  nStr := 'Select sc.*,sm.S_Name,sm.S_PY,cus.C_Name as CusName,' +
          '$Now as S_Now From $SC sc' +
          ' Left Join $SM sm On sm.S_ID=sc.C_SaleMan' +
          ' Left Join $Cus cus On cus.C_ID=sc.C_Customer ' +
          'Where sc.C_ID=''$ID''';
  nStr := MacroValue(nStr, [MI('$SC', sTable_SaleContract),
          MI('$SM', sTable_Salesman), MI('$Cus', sTable_Customer),
          MI('$ID', nCID), MI('$Now', FDM.SQLServerNow)]);

  with FDM.QuerySQL(nStr) do
  if RecordCount > 0 then
  begin
    with gZhiKa do
    begin
      FIsXuNi := FieldByName('C_XuNi').AsString = sFlag_Yes;
      FSaleMan := FieldByName('C_SaleMan').AsString;
      FSaleName := FieldByName('S_Name').AsString;
      FSalePY := FieldByName('S_PY').AsString;
      FCustomer := FieldByName('C_Customer').AsString;
      FCusName := FieldByName('CusName').AsString;
    end;

    EditPName.Text := FieldByName('C_Project').AsString;
    EditDays.Date := FieldByName('S_Now').AsFloat +
                     FieldByName('C_ZKDays').AsInteger;
    //当前 + 时长
    
    EditPName.Properties.ReadOnly := not gZhiKa.FIsXuNi;
    EditSMan.Properties.ReadOnly := not gZhiKa.FIsXuNi;
    EditCustom.Properties.ReadOnly := not gZhiKa.FIsXuNi;

    if gZhiKa.FIsXuNi then
    begin
      EditSMan.Properties.DropDownListStyle := lsEditFixedList;
      EditCustom.Properties.DropDownListStyle := lsEditList;

      if EditSMan.Properties.Items.Count < 1 then
        LoadSaleMan(EditSMan.Properties.Items);
      SetCtrlData(EditSMan, gZhiKa.FSaleMan);
      //设置业务员

      if EditCustom.Properties.Items.Count < 1 then
      begin
        nStr := Format('C_SaleMan=''%s''', [GetCtrlData(EditSMan)]);
        LoadCustomer(EditCustom.Properties.Items, nStr);
      end;
      SetCtrlData(EditCustom, gZhika.FCustomer);
      //设置客户名
    end else
    begin
      EditSMan.Properties.DropDownListStyle := lsEditList;
      EditCustom.Properties.DropDownListStyle := lsEditList;

      EditSMan.Text := Format('%s.%s', [gZhiKa.FSalePY, gZhiKa.FSaleName]);
      EditCustom.Text := Format('%s.%s', [gZhiKa.FCustomer, gZhiKa.FCusName]);
    end;

    SetLength(gStockList, 0);
    nStr := 'Select * From %s Where E_CID=''%s''';
    nStr := Format(nStr, [sTable_SContractExt, nCID]);

    with FDM.QuerySQL(nStr) do
    if RecordCount > 0 then
    begin
      SetLength(gStockList, RecordCount);
      nIdx := 0;
      First;

      while not Eof do
      with gStockList[nIdx] do
      begin
        FType := FieldByName('E_Type').AsString;
        FName := FieldByName('E_Stock').AsString;
        FPrice := FieldByName('E_Price').AsFloat;
        FValue := 0;

        Next;
        Inc(nIdx);
      end;
    end;

    LoadStockList;
    EditCID.Text := nCID;
    
    gZhiKa.FIsValid := True;
    gZhiKa.FContract := nCID;
  end;
end;

//Desc: 业务员变更,提取相关客户
procedure TfFormZhiKa.EditSManPropertiesEditValueChanged(Sender: TObject);
var nStr: string;
begin
  if gZhiKa.FIsXuNi and (EditSMan.ItemIndex > -1) then
  begin
    EditCustom.Text := '';
    nStr := Format('C_SaleMan=''%s''', [GetCtrlData(EditSMan)]);
    LoadCustomer(EditCustom.Properties.Items, nStr);
  end;
end;

//Desc: 载入合同
procedure TfFormZhiKa.EditCIDExit(Sender: TObject);
begin
  EditCID.Text := Trim(EditCID.Text);
  if EditCID.Text <> '' then LoadSaleContract(EditCID.Text);
end;

//Desc: 同步更新办理明细
procedure TfFormZhiKa.ListDetailClick(Sender: TObject);
var nIdx: Integer;
    nChanged: Boolean;
begin
  nChanged := False;
  for nIdx:=Low(gStockList) to High(gStockList) do
  if gStockList[nIdx].FSelected <> ListDetail.Items[nIdx].Checked then
  begin
    nChanged := True;
    gStockList[nIdx].FSelected := ListDetail.Items[nIdx].Checked;
  end;

  if nChanged then LoadStockListSummary;
  //update summary
  
  if ListDetail.ItemIndex >= 0 then
  begin
    EditStock.Text := gStockList[ListDetail.ItemIndex].FName;
    EditPrice.Text := Format('%.2f', [gStockList[ListDetail.ItemIndex].FPrice]);
    
    EditValue.Text := Format('%.2f', [gStockList[ListDetail.ItemIndex].FValue]);
    //EditValue.SetFocus;
  end;
end;

//Desc: 跟新设置
procedure TfFormZhiKa.EditPriceExit(Sender: TObject);
var nInt: Integer;
    nChanged: Boolean;
begin
  if (ListDetail.ItemIndex >= 0) and IsNumber(EditPrice.Text, True) and
     IsNumber(EditValue.Text, True) then
  begin
    nInt := Float2PInt(StrToFloat(EditPrice.Text), cPrecision);
    if nInt <> Float2PInt(gStockList[ListDetail.ItemIndex].FPrice, cPrecision) then
    begin
      nChanged := True;
      gStockList[ListDetail.ItemIndex].FPrice := nInt / cPrecision;
    end else nChanged := False;

    nInt := Float2PInt(StrToFloat(EditValue.Text), cPrecision);
    if nInt <> Float2PInt(gStockList[ListDetail.ItemIndex].FValue, cPrecision) then
    begin
      nChanged := True;
      gStockList[ListDetail.ItemIndex].FValue := nInt / cPrecision;
    end;

    if nChanged then
    begin
      LoadStockList;
      LoadStockListSummary;
    end;
  end;
end;

//Desc: 快捷菜单
procedure TfFormZhiKa.N3Click(Sender: TObject);
var nIdx: integer;
    nBool: Boolean;
begin
  for nIdx:=Low(gStockList) to High(gStockList) do
  begin
    case TComponent(Sender).Tag of
     10: nBool := True;
     20: nBool := False;
     30: nBool := not gStockList[nIdx].FSelected else nBool := False;
    end;

    gStockList[nIdx].FSelected := nBool;
    ListDetail.Items[nIdx].Checked := nBool;
    LoadStockListSummary;
  end;
end;

//Desc: 快速选择合同
procedure TfFormZhiKa.EditCIDKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    TcxButtonEdit(Sender).Properties.OnButtonClick(Sender, 0);
  end;
end;

//Desc: 快速选择客户
procedure TfFormZhiKa.EditCustomKeyPress(Sender: TObject; var Key: Char);
var nStr: string;
    nP: TFormCommandParam;
begin
  if Key = #13 then
  begin
    Key := #0;
    nP.FParamA := GetCtrlData(EditCustom);
    
    if nP.FParamA = '' then
      nP.FParamA := EditCustom.Text;
    //xxxxx

    CreateBaseFormItem(cFI_FormGetCustom, '', @nP);
    if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOK) then Exit;

    SetCtrlData(EditSMan, nP.FParamD);
    if EditSMan.ItemIndex < 0 then
    begin
      ShowMsg('无效的业务员', sHint); Exit;
    end;

    SetCtrlData(EditCustom, nP.FParamB);
    if EditCustom.ItemIndex < 0 then
    begin
      nStr := Format('%s=%s.%s', [nP.FParamB, nP.FParamB, nP.FParamC]);
      InsertStringsItem(EditCustom.Properties.Items, nStr);
      SetCtrlData(EditCustom, nP.FParamB);
    end;
  end;
end;

procedure TfFormZhiKa.EditCIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nP: TFormCommandParam;
begin
  nP.FParamA := Trim(EditCID.Text);
  CreateBaseFormItem(cFI_FormGetContract, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
    LoadSaleContract(nP.FParamB);
  EditCID.SelectAll;
end;

//Desc: 验证Sender控件
function TfFormZhiKa.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
begin
  Result := True;
  if Sender = EditCID then
  begin
    Result := gZhiKa.FIsValid;
    nHint := '请填写有效的合同编号';
  end else

  if Sender = EditSMan then
  begin
    Result := (not gZhiKa.FIsXuNi) or (EditSMan.ItemIndex >= 0);
    nHint := '请选择有效的业务员';
  end else

  if Sender = EditCustom then
  begin
    Result := (not gZhiKa.FIsXuNi) or (EditCustom.Text <> '');
    nHint := '请选择有效的客户';
  end else

  if Sender = EditDays then
  begin
    Result := EditDays.Text <> '';
    nHint := '请填写有效的时长';
  end else

  if Sender = EditMoney then
  begin
    Result := IsNumber(EditMoney.Text, True) and (StrToFloat(EditMoney.Text) >= 0);
    nHint := '请输入有效的预付金额';
  end;
end;

//Desc: 获取nCusID的当前可用金额
function GetCustomValidMoney(const nCusID: string): string;
var nStr: string;
    nVal: Double;
begin
  nStr := 'Select Sum(Z_FixedMoney) From %s ' +
          'Where Z_Custom=''%s'' and Z_OnlyMoney=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa, nCusID, sFlag_Yes]);

  nVal := FDM.QueryTemp(nStr).Fields[0].AsFloat;
  nVal := GetCustomerValidMoney(nCusID) - nVal;
  
  if nVal < 0 then
       Result := '0'
  else Result := Format('%.2f', [nVal]);
end;

//Desc: 保存数据
procedure TfFormZhiKa.BtnOKClick(Sender: TObject);
var nIdx: integer;
    nList: TStrings;
    nDoCard: Boolean;
    nParam: TFormCommandParam;
    nStr,nSQL,nZID,nCID: string;
begin
  if not IsDataValid then Exit;
  if gZhiKa.FIsXuNi then
  begin
    if EditCustom.ItemIndex > -1 then
         nCID := GetCtrlData(EditCustom)
    else nCID := SaveXuNiCustomer(EditCustom.Text, GetCtrlData(EditSMan));
  end else nCID := gZhiKa.FCustomer;

  if FRecordID = '' then
  begin
    nParam.FCommand := cCmd_EditData;
    nParam.FParamA := nCID;
    CreateBaseFormItem(cFI_FormZhiKaAdjust, '', @nParam);

    if (nParam.FCommand <> cCmd_ModalResult) or (nParam.FParamA <> mrOK) then
      Exit;
    //旧卡校正没有完成
  end;

  nList := TStringList.Create;
  FDM.ADOConn.BeginTrans;
  try
    if gZhika.FIsXuNi then
         nStr := GetCtrlData(EditSMan)
    else nStr := gZhiKa.FSaleMan;

    nList.Add(Format('Z_Custom=''%s''', [nCID]));
    nList.Add(Format('Z_SaleMan=''%s''', [nStr]));
    nList.Add(Format('Z_CID=''%s''', [gZhiKa.FContract]));
    nList.Add(Format('Z_Project=''%s''', [Trim(EditPName.Text)]));
    
    nList.Add(Format('Z_Payment=''%s''', [EditPayment.Text]));
    nList.Add(Format('Z_Lading=''%s''', [GetCtrlData(EditLading)]));
    nList.Add(Format('Z_ValidDays=''%s''', [Date2Str(EditDays.Date)]));
    nList.Add(Format('Z_YFMoney=%s', [EditMoney.Text]));

    if FRecordID = '' then
    begin
      nDoCard := not IsZhiKaNeedVerify;
      if nDoCard then
           nStr := sFlag_Yes
      else nStr := sFlag_No;
      nList.Add(Format('Z_Verified=''%s''', [nStr]));

      nList.Add(Format('Z_Man=''%s''', [gSysParam.FUserName]));
      nList.Add(Format('Z_Date=%s', [FDM.SQLServerNow]));
      nSQL := MakeSQLByForm(Self, sTable_ZhiKa, '', True, nil, nList);
    end else
    begin
      nDoCard := False;
      nStr := Format('Z_ID=''%s''', [FRecordID]);
      nSQL := MakeSQLByForm(Self, sTable_ZhiKa, nStr, False, nil, nList);
    end;

    FDM.ExecuteSQL(nSQL);
    //write data

    if FRecordID = '' then
    begin
      nIdx := FDM.GetFieldMax(sTable_ZhiKa, 'R_ID');
      nZID := FDM.GetSerialID2(FPrefixID, sTable_ZhiKa, 'R_ID', 'Z_ID', nIdx);

      nSQL := 'Update %s Set Z_ID=''%s'' Where R_ID=%d';
      nSQL := Format(nSQL, [sTable_ZhiKa, nZID, nIdx]);
      FDM.ExecuteSQL(nSQL);
    end else nZID := FRecordID;

    if FRecordID <> '' then
    begin
      nSQL := 'Delete From %s Where D_ZID=''%s''';
      nSQL := Format(nSQL, [sTable_ZhiKaDtl, nZID]);
      FDM.ExecuteSQL(nSQL);
    end;

    nStr := 'Insert Into %s(D_ZID,D_Type,D_Stock,D_Price,D_Value) ' +
            'Values(''%s'',''$T'',''$S'',$P,$V)';
    nStr := Format(nStr, [sTable_ZhiKaDtl, nZID]);

    for nIdx:=Low(gStockList) to High(gStockList) do
    with gStockList[nIdx] do
    begin
      if not FSelected then Continue;
      nSQL := MacroValue(nStr, [MI('$T', FType), MI('$S', FName),
              MI('$P', Format('%.2f', [FPrice])),
              MI('$V', Format('%.2f', [FValue]))]);
      FDM.ExecuteSQL(nSQL);
    end;

    if nParam.FParamB <> '' then
    begin
      nList.Text := MacroValue(nParam.FParamB, [MI('$NewZK', nZID)]);
      if Pos('$Money', nList.Text) > 0 then
      begin
        nStr := GetCustomValidMoney(gZhiKa.FCustomer);
        nList.Text := MacroValue(nList.Text, [MI('$Money', nStr)]);
      end;

      for nIdx:=nList.Count - 1 downto 0 do
        FDM.ExecuteSQL(nList[nIdx]);
      //xxxxx
    end;
    //旧卡调整

    FreeAndNil(nList);
    FDM.ADOConn.CommitTrans;

    if Check1.Checked then
    begin
      Visible := False;
      Application.ProcessMessages;

      nParam.FParamA := nZID;
      CreateBaseFormItem(cFI_FormZhiKaFixMoney, '', @nParam);

      Visible := True;
      Application.ProcessMessages;
    end; //限提

    if nDoCard and QueryDlg('现在是否办理磁卡?', sAsk, Handle) then
    begin
      Visible := False;
      Application.ProcessMessages;
      
      nParam.FParamA := nZID;
      CreateBaseFormItem(cFI_FormZhiKaCard, '', @nParam);

      Visible := True;
      Application.ProcessMessages;
    end; //磁卡

    ModalResult := mrOK;
    ShowMsg('纸卡已保存', sHint);
  except
    nList.Free;
    if FDM.ADOConn.InTransaction then
      FDM.ADOConn.RollbackTrans;
    ShowMsg('纸卡保存失败', sError);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormZhiKa, TfFormZhiKa.FormID);
end.
