{*******************************************************************************
  作者: dmzn@163.com 2009-7-15
  描述: 纸卡办理明细查询
*******************************************************************************}
unit UFrameZhiKaDetail;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, Menus, dxLayoutControl,
  cxMaskEdit, cxButtonEdit, cxTextEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFrameZhiKaDetail = class(TfFrameNormal)
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditCus: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    EditZK: TcxButtonEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    cxTextEdit4: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    N5: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N12: TMenuItem;
    N13: TMenuItem;
    N14: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N6: TMenuItem;
    N10: TMenuItem;
    procedure EditZKPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N1Click(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N8Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N13Click(Sender: TObject);
    procedure PMenu1Popup(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    //时间区间
    FDateFilte: Boolean;
    //启用区间
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    procedure AfterInitFormData; override;
    function InitFormDataSQL(const nWhere: string): string; override;
    {*查询SQL*}
    procedure FreezeZK(const nFreeze: Boolean);
    //冻结选中提货单
    procedure SelectedZK(const nList: TStrings);
    //获取选中纸卡号
    function GetVal(const nRow: Integer; const nField: string): string;
    //获取指定字段
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysConst, USysDB, UDataModule, UFormDateFilter,
  UFormBase, UFrameBase;

//------------------------------------------------------------------------------
class function TfFrameZhiKaDetail.FrameID: integer;
begin
  Result := cFI_FrameZhiKaDetail;
end;

procedure TfFrameZhiKaDetail.OnCreateFrame;
begin
  inherited;
  FDateFilte := True;
  InitDateRange(Name, FStart, FEnd);
end;

procedure TfFrameZhiKaDetail.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

function TfFrameZhiKaDetail.InitFormDataSQL(const nWhere: string): string;
begin  
  EditDate.Text := Format('%s 至 %s', [Date2Str(FStart), Date2Str(FEnd)]);

  Result := 'Select zk.*,zd.*,zd.R_ID as D_RID,S_PY,S_Name,C_PY,C_Name From $ZK zk ' +
            ' Left Join $SM sm on sm.S_ID=zk.Z_SaleMan' +
            ' Left Join $Cus cus on cus.C_ID=zk.Z_Custom' +
            ' Left Join $ZD zd on zd.D_ZID=zk.Z_ID ';
  //xxxxx

  if nWhere = '' then
       Result := Result + ' Where (Z_InValid Is Null or Z_InValid<>''$Yes'')'
  else Result := Result + ' Where (' + nWhere + ')';

  if FDateFilte then
    Result := Result + ' and (Z_Date>=''$STT'' and Z_Date<''$End'')';
  //xxxxx

  Result := MacroValue(Result, [MI('$ZK', sTable_ZhiKa), MI('$Yes', sFlag_Yes),
            MI('$ZD', sTable_ZhiKaDtl), MI('$SM', sTable_Salesman),
            MI('$Cus', sTable_Customer),
            MI('$STT', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
  //xxxxx
end;

procedure TfFrameZhiKaDetail.AfterInitFormData;
begin
  FDateFilte := True;
end;

//Desc: 查询
procedure TfFrameZhiKaDetail.EditZKPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditZK then
  begin
    EditZK.Text := Trim(EditZK.Text);
    if EditZK.Text = '' then Exit;

    FWhere := Format('Z_ID Like ''%%%s%%''', [EditZK.Text]);
    FDateFilte := False;
    InitFormData(FWhere);
  end else

  if Sender = EditCus then
  begin
    EditCus.Text := Trim(EditCus.Text);
    if EditCus.Text = '' then Exit;

    FWhere := Format('C_PY Like ''%%%s%%'' or C_Name Like ''%%%s%%''',
              [EditCus.Text, EditCus.Text]);
    InitFormData(FWhere);
  end;
end;

//Desc: 日期筛选
procedure TfFrameZhiKaDetail.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

//------------------------------------------------------------------------------
//Desc: 获取nRow行nField字段的内容
function TfFrameZhiKaDetail.GetVal(const nRow: Integer;
 const nField: string): string;
var nVal: Variant;
begin
  nVal := cxView1.DataController.GetValue(
            cxView1.Controller.SelectedRows[nRow].RecordIndex,
            cxView1.GetColumnByFieldName(nField).Index);
  //xxxxx

  if VarIsNull(nVal) then
       Result := ''
  else Result := nVal;
end;

//Desc: 获取选中纸卡列表
procedure TfFrameZhiKaDetail.SelectedZK(const nList: TStrings);
var nStr: string;
    nIdx: Integer;
begin
  nList.Clear;
  for nIdx:=cxView1.Controller.SelectedRowCount - 1 downto 0 do
  begin
    nStr := GetVal(nIdx, 'Z_ID');
    if (nStr <> '') and (nList.IndexOf(nStr) < 0) then
      nList.Add(nStr);
    //xxxxx
  end;
end;

//Desc: 冻结当前选中的提货单
procedure TfFrameZhiKaDetail.FreezeZK(const nFreeze: Boolean);
var nStr: string;
    nIdx: Integer;
    nList: TStrings;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
    Exit;
  //xxxxx

  nList := TStringList.Create;
  try
    SelectedZK(nList);
    if nList.Count < 1 then Exit;

    FDM.ADOConn.BeginTrans;
    try
      for nIdx:=nList.Count - 1 downto 0 do
      begin
        if nFreeze then
        begin
          nStr := 'Update %s Set Z_TJStatus=''%s'' Where Z_ID=''%s'' and ' +
                  'IsNull(Z_InValid,'''')<>''%s'' And Z_ValidDays>%s';
          nStr := Format(nStr, [sTable_ZhiKa, sFlag_TJing, nList[nIdx], 
                  sFlag_Yes, FDM.SQLServerNow]);
          //调价中
        end else
        begin
          nStr := 'Update %s Set Z_TJStatus=''%s'' Where Z_ID=''%s'' and ' +
                  'Z_TJStatus=''%s''';
          nStr := Format(nStr, [sTable_ZhiKa, sFlag_TJOver, nList[nIdx],
                  sFlag_TJing]);
          //调价结束
        end;

        FDM.ExecuteSQL(nStr);
      end;

      FDM.ADOConn.CommitTrans;
      ShowMsg('操作成功', sHint);
    except
      FDM.ADOConn.RollbackTrans;
      ShowMsg('操作失败', sError);
    end;
  finally
    nList.Free;
  end;
end;

//Desc: 处理权限
procedure TfFrameZhiKaDetail.PMenu1Popup(Sender: TObject);
begin
  N7.Enabled := BtnAdd.Enabled;
  N8.Enabled := BtnAdd.Enabled;
  N10.Enabled := BtnAdd.Enabled;
  N13.Enabled := BtnEdit.Enabled;
  N14.Enabled := BtnEdit.Enabled;
end;

//Desc: 快捷查询
procedure TfFrameZhiKaDetail.N1Click(Sender: TObject);
begin
  case TComponent(Sender).Tag of
   10: begin
         FWhere := 'Z_InValid=''$Yes'' Or Z_ValidDays<=%s';
         FWhere := Format(FWhere, [FDM.SQLServerNow]);
       end;
   20: FWhere := '1=1';
   30: FreezeZK(True);
   40: FreezeZK(False);
   50: begin
         FDateFilte := False;
         FWhere := Format('Z_TJStatus=''%s''', [sFlag_TJing]);
       end else Exit;
  end;

  InitFormData(FWhere);
end;

//Desc: 按品种冻结
procedure TfFrameZhiKaDetail.N8Click(Sender: TObject);
var nP: TFormCommandParam;
begin
  nP.FCommand := cCmd_ModalResult;
  CreateBaseFormItem(cFI_FormFreezeZK, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOk) then
  begin
    InitFormData(FWhere);
  end;
end;

//Desc: 选中纸卡调价
procedure TfFrameZhiKaDetail.N6Click(Sender: TObject);
var nList: TStrings;
    nIdx,nLen: Integer;
    nP: TFormCommandParam;
    nStr,nRID,nZID,nStock,nType: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
    Exit;
  //xxxxx

  nList := TStringList.Create;
  try
    nType := GetVal(0, 'D_Type');
    nStock := GetVal(0, 'D_Stock');
    nLen := cxView1.DataController.GetSelectedCount - 1;

    for nIdx:=0 to nLen do
    begin
      nRID := GetVal(nIdx, 'D_RID');
      nZID := GetVal(nIdx, 'Z_ID');
      if (nRID = '') or (nZID = '') then Continue;

      nStr := GetVal(nIdx, 'Z_TJStatus');
      if nStr <> sFlag_TJing then
      begin
        nStr := '调价前需要冻结纸卡,记录[ %s ]不符合要求.';
        nStr := Format(nStr, [nRID]);
        ShowDlg(nStr, sHint, Handle); Exit;
      end;
      
      if (GetVal(nIdx, 'D_Type') <> nType) or
         (GetVal(nIdx, 'D_Stock') <> nStock) then
      begin
        nStr := '只有同品种的水泥才能统一调价,记录[ %s ]不符合要求.';
        nStr := Format(nStr, [nRID]);
        ShowDlg(nStr, sHint, Handle); Exit;
      end;

      nStr := Format('%s;%s;%s;%s', [nRID,
              GetVal(nIdx, 'D_Price'), nZID, nStock]);
      nList.Add(nStr);
    end;

    if nList.Count < 1 then
    begin
      ShowMsg('选中记录无效', sHint); Exit;
    end;

    nP.FCommand := cCmd_ModalResult;
    nP.FParamA := Integer(nList);
    CreateBaseFormItem(cFI_FormAdjustPrice, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOk) then
    begin
      InitFormData(FWhere);
    end;
  finally
    nList.Free;
  end;
end;

//Desc: 查看变价记录
procedure TfFrameZhiKaDetail.N13Click(Sender: TObject);
var nStr: string;
    nParam: TFrameCommandParam;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nParam.FCommand := cCmd_ViewSysLog;
    nParam.FParamA := '2008-08-08';
    nParam.FParamB := '2050-12-12';

    nStr := 'L_Group=''$Group'' And L_ItemID=''$ID''';
    nParam.FParamC := MacroValue(nStr, [MI('$Group', sFlag_ZhiKaItem),
                      MI('$ID', SQLQuery.FieldByName('Z_ID').AsString)]);
    //检索条件

    CreateBaseFrameItem(cFI_FrameSysLog, Parent, 'MAIN_A02');
    BroadcastFrameCommand(Self, Integer(@nParam));
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameZhiKaDetail, TfFrameZhiKaDetail.FrameID);
end.
