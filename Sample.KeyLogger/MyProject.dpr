program MyProject;

uses
  Forms,
  MyUnit in 'MyUnit.pas' {MyForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMyForm, MyForm);
  Application.Run;
end.
