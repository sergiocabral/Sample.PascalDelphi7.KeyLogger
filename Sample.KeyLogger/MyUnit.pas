unit MyUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TMyForm = class(TForm)
    btnStartHook: TButton;
    btnStopHook: TButton;
    txtCapure: TMemo;
    procedure btnStartHookClick(Sender: TObject);
    procedure btnStopHookClick(Sender: TObject);
  private
    hDllGetProcAddress: THandle;
    DllReceiveText: string;
    procedure DllMessage(var Msg: TMessage); message WM_USER + 1678;
  public
  end;

var
  MyForm: TMyForm;

implementation

{$R *.dfm}

procedure TMyForm.DllMessage(var Msg: TMessage);
begin
  // Ignora caracteres: 8=Backspace, 13=Enter.
  if (Msg.wParam = 8) or (Msg.wParam = 13) then Exit;

  DllReceiveText := DllReceiveText + Chr(Msg.wParam);

  txtCapure.Text := DllReceiveText;
end;

procedure TMyForm.btnStartHookClick(Sender: TObject);
type
  TStartHook = function(MemoHandle, AppHandle: HWND): Byte;
var
  StartHook: TStartHook;
  SHresult: Byte;
begin
  hDllGetProcAddress := LoadLibrary('HookDll.dll');
  @StartHook := GetProcAddress(hDllGetProcAddress, 'StartHook');
  if @StartHook = nil then
  begin
    ShowMessage('FAIL: StartHook = nil');
    Exit;
  end;

  SHresult := StartHook(txtCapure.Handle, Handle);

  if SHresult = 0 then ShowMessage('SUCESS: Hook started.');
  if SHresult = 1 then ShowMessage('INFO: Hook was already started.');
  if SHresult = 2 then ShowMessage('FAIL: Hook can NOT be Started.');
  if SHresult = 4 then ShowMessage('FAIL: MemoHandle is incorrect');
end;

procedure TMyForm.btnStopHookClick(Sender: TObject);
type
  TStopHook = function: Boolean;
var
  StopHook: TStopHook;
  SHresult: Boolean;
begin
  @StopHook := GetProcAddress(hDllGetProcAddress, 'StopHook');

  if @StopHook = nil then
  begin
    ShowMessage('FAIL: StopHook = nil');
    Exit;
  end;

  SHresult := StopHook();

  if SHresult then ShowMessage('SUCESS: Hook stoped')
  else ShowMessage('FAIL: Hook NOT was stoped');

  FreeLibrary(hDllGetProcAddress);
  FreeLibrary(hDllGetProcAddress); // Por alguma razão deve ser chamda 2x porque no WinXP retorna 2 funções da DLL.
end;

end.

