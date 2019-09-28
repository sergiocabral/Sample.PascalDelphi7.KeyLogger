library HookDll;

uses
  Forms,
  Windows,
  Messages,
  SysUtils;

type
  PHookRec = ^THookRec;

  THookRec = record
    AppHnd: integer;
    MemoHnd: integer;
  end;

var
  Hooked: boolean;
  hKeyHook, hMemo, hMemFile, hApp: HWND;
  PHookRec1: PHookRec;

function KeyHookFunc(Code, VirtualKey, KeyStroke: integer): LRESULT; stdcall;
var
  KeyState1: TKeyBoardState;
  AryChar: array[0..1] of char;
  Count: integer;
begin
  result := 0;
  if Code = HC_NOREMOVE then
    exit;
  result := CallNextHookEx(hKeyHook, Code, VirtualKey, KeyStroke);
  {I moved the CallNextHookEx up here but if you want to block
   or change any keys then move it back down}
  if Code < 0 then
    exit;

  if Code = HC_ACTION then
  begin
    if ((KeyStroke and (1 shl 30)) <> 0) then
      if not IsWindow(hMemo) then
      begin
       {I moved the OpenFileMapping up here so it would not be opened
        unless the app the DLL is attatched to gets some Key messages}
        hMemFile := OpenFileMapping(FILE_MAP_WRITE, false, 'Global7v9k');
        PHookRec1 := MapViewOfFile(hMemFile, FILE_MAP_WRITE, 0, 0, 0);
        if PHookRec1 <> nil then
        begin
          hMemo := PHookRec1.MemoHnd;
          hApp := PHookRec1.AppHnd;
        end;
      end;
    if ((KeyStroke and (1 shl 30)) <> 0) then
    begin
      GetKeyboardState(KeyState1);
      Count := ToAscii(VirtualKey, KeyStroke, KeyState1, AryChar, 0);
      if Count = 1 then
      begin
        SendMessage(hMemo, WM_CHAR, Ord(AryChar[0]), 0);
        {I included 2 ways to get the Charaters, a Memo Hnadle and
         a WM_USER+1678 message to the program}
        PostMessage(hApp, WM_USER + 1678, Ord(AryChar[0]), 0);
      end;
    end;
  end;
end;

function StartHook(MemoHandle, AppHandle: HWND): byte; export;
begin
  result := 0;
  if Hooked then
  begin
    result := 1;
    exit;
  end;
  if not IsWindow(MemoHandle) then
  begin
    result := 4;
    exit;
  end;
  hKeyHook := SetWindowsHookEx(WH_KEYBOARD, KeyHookFunc, hInstance, 0);
  if hKeyHook > 0 then
  begin
    {you need to use a mapped file because this DLL attatches to every app
     that gets windows messages when it's hooked, and you can't get info except
     through a Globally avaiable Mapped file}
    hMemFile := CreateFileMapping($FFFFFFFF, // $FFFFFFFF gets a page memory file
      nil,                // no security attributes
      PAGE_READWRITE,     // read/write access
      0,                  // size: high 32-bits
      SizeOf(THookRec),   // size: low 32-bits
      //SizeOf(Integer),
      'Global7v9k');    // name of map object
    PHookRec1 := MapViewOfFile(hMemFile, FILE_MAP_WRITE, 0, 0, 0);

    hMemo := MemoHandle;
    PHookRec1.MemoHnd := MemoHandle;
    hApp := AppHandle;
    PHookRec1.AppHnd := AppHandle;
    {set the Memo and App handles to the mapped file}
    Hooked := true;
  end
  else
    result := 2;
end;

function StopHook: boolean; export;
begin
  if PHookRec1 <> nil then
  begin
    UnmapViewOfFile(PHookRec1);
    CloseHandle(hMemFile);
    PHookRec1 := nil;
  end;
  if Hooked then
    result := UnhookWindowsHookEx(hKeyHook)
  else
    result := true;
  Hooked := false;
end;

procedure EntryProc(dwReason: DWORD);
begin
  if (dwReason = Dll_Process_Detach) then
  begin
    if PHookRec1 <> nil then
    begin
      UnmapViewOfFile(PHookRec1);
      CloseHandle(hMemFile);
    end;
    UnhookWindowsHookEx(hKeyHook);
  end;
end;

exports
  StartHook,
  StopHook;

begin
  PHookRec1 := nil;
  Hooked := false;
  hKeyHook := 0;
  hMemo := 0;
  DLLProc := @EntryProc;
  EntryProc(Dll_Process_Attach);
end.
