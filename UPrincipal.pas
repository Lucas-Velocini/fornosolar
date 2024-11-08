unit UPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.TabControl, FMX.Objects,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit,

  RESTRequest4D, DataSet.Serialize.Adapter.RESTRequest4D, System.JSON, System.Net.HttpClient, Loading,
  uSuperChartLight;

type
  TForm1 = class(TForm)
    lytTopo: TLayout;
    lytBtnTopo: TLayout;
    lblConectar: TLabel;
    lytLblTopo: TLayout;
    lytMenu: TLayout;
    TabControlPrincipal: TTabControl;
    tabPrincipal: TTabItem;
    tabGraficos: TTabItem;
    tabTempo: TTabItem;
    Rectangle1: TRectangle;
    lblBtnConectar: TLabel;
    btnConectar: TRoundRect;
    rctMenu: TRectangle;
    lytMenuPrinc: TLayout;
    lytMenuInfos: TLayout;
    lytMenuTempo: TLayout;
    btnPrincipal: TImage;
    btnInfos: TImage;
    btnTempo: TImage;
    RoundRect1: TRoundRect;
    lytDisplayTemp: TLayout;
    lblC: TLabel;
    lblTemperatura: TLabel;
    swtTemp: TSwitch;
    lblTravarTemp: TLabel;
    sldTemp: TTrackBar;
    lblSliderTemp: TLabel;
    lytBtnCozinhar: TLayout;
    btnIniciar: TRoundRect;
    lblIniciar: TLabel;
    lytControles: TLayout;
    Layout1: TLayout;
    Layout2: TLayout;
    RoundRect2: TRoundRect;
    rctStatus: TRoundRect;
    lblStatus: TLabel;
    imgLogo: TImage;
    rctFundo: TRectangle;
    rectFundoTela3: TRectangle;
    Line3: TLine;
    rectFundoTela2: TRectangle;
    imgGraficoBranco: TImage;
    imgTermometroBranco: TImage;
    imgRelogioBranco: TImage;
    ImageControl1: TImageControl;
    imgTermometroAmarelo: TImage;
    imgGraficoAmarelo: TImage;
    imgRelogioAmarelo: TImage;
    rctTemperatura: TRectangle;
    lblIlimitado: TLabel;
    rctFundoGrafico: TRectangle;
    lytGrafico: TLayout;
    lblGrafico: TLabel;
    logGrafico: TMemo;
    btnServo: TButton;
    sldServo: TTrackBar;
    lblAngulo: TLabel;
    btnLimpar: TButton;
    procedure btnPrincipalClick(Sender: TObject);
    procedure btnInfosClick(Sender: TObject);
    procedure btnTempoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sldTempChange(Sender: TObject);
    procedure swtTempSwitch(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure sldServoChange(Sender: TObject);
    procedure btnServoClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
  private
    procedure montarGrafico(jsonStr: string);
    procedure TThreadEnd(Sender: TObject);
    //function CheckInternet: boolean;
    { Private declarations }
  public
    { Public declarations }
    const laranja = $FFFC7100;
    const vermelho = $FFFF0400;
    const verde = $FF00B02C;
    const amarelo = $FFFFE100;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

{...............PROCEDURES...............}

procedure TForm1.FormCreate(Sender: TObject);
begin
  TabControlPrincipal.GoToVisibleTab(0);
  lblSliderTemp.Text := '100 ' + '°C';
  sldTemp.Value := 100;
  TabControlPrincipal.GotoVisibleTab(0);
  btnPrincipal.Bitmap := imgTermometroBranco.Bitmap;

  //Verificanco a conexão com o ESP32
  {if NOT CheckInternet then
    lblConectar.Text := 'Forno não conectado'
  else
    lblConectar.Text := 'Forno Conectado';}
end;

procedure TForm1.montarGrafico(jsonStr: string);
var
  chart: TSuperChart;
  erro: string;
begin
  try
    chart := TSuperChart.Create(lytGrafico, lines);

    chart.ShowValues := true;
    chart.FontSizeValues := 10;
    chart.FontColorValues := amarelo;
    chart.FormatValues := '#,#0.0';

    chart.LineColor := TAlphaColorRec.White;

    chart.FontSizeArgument := 9;
    chart.FontColorArgument := TAlphaColorRec.White;

    chart.LoadFromJSON(jsonStr, erro);

    if NOT erro.isEmpty then
      showmessage(erro);

  finally
    chart.Free;
  end;
end;

procedure TForm1.btnConectarClick(Sender: TObject);
begin
  TLoading.Show(Form1, 'Verificando conexão...');

  TThread.CreateAnonymousThread(procedure
  var
    response: IResponse;
  begin

    try
      response := TRequest.New.BaseURL('fornosolar.local/conexao')
              .Accept('application/json')
              .Get;
    except
      TThread.Synchronize(nil, procedure
        begin
          lblConectar.Text := 'Forno não conectado';
          ShowMessage('Não foi possivel encontrar o forno!' + sLineBreak +
          'Verifique se seu dispositivo está conectado a rede "FornoSolar" e tente novamente.');
          TLoading.Hide;
        end);
    end;

    if response.Content = 'Servidor online!!' then
      begin
        TThread.Synchronize(nil, procedure
        begin
          lblConectar.Text := 'Forno conectado';
          TLoading.Hide;
        end);
      end
    else
      begin
        TThread.Synchronize(nil, procedure
        begin
          lblConectar.Text := 'Forno não conectado';
          TLoading.Hide;
        end);
      end;
  end).Start;

end;

procedure TForm1.btnPrincipalClick(Sender: TObject);
begin
  btnInfos.Bitmap := imgGraficoAmarelo.Bitmap;
  btnPrincipal.Bitmap := imgTermometroBranco.Bitmap;
  btnTempo.Bitmap := imgRelogioAmarelo.Bitmap;
  TabControlPrincipal.GoToVisibleTab(0);
end;

procedure TForm1.btnServoClick(Sender: TObject);
begin
  TThread.CreateAnonymousThread(procedure
  var
    response: IResponse;
  begin

    try
      response := TRequest.New.BaseURL('fornosolar.local/servo')
              .Accept('application/json')
              .AddBody(lblAngulo.Text)
              .post;
    except
      TThread.Synchronize(nil, procedure
        begin
          lblConectar.Text := 'Forno não conectado';
          ShowMessage('Não foi possivel encontrar o forno!' + sLineBreak +
          'Verifique se seu dispositivo está conectado a rede "FornoSolar" e tente novamente.');
          TLoading.Hide;
        end);
    end;
  end).Start;
end;

procedure TForm1.btnInfosClick(Sender: TObject);
begin
  btnInfos.Bitmap := imgGraficoBranco.Bitmap;
  btnPrincipal.Bitmap := imgTermometroAmarelo.Bitmap;
  btnTempo.Bitmap := imgRelogioAmarelo.Bitmap;
  TabControlPrincipal.GoToVisibleTab(1);
end;

procedure TForm1.btnTempoClick(Sender: TObject);
begin
  btnInfos.Bitmap := imgGraficoAmarelo.Bitmap;
  btnPrincipal.Bitmap := imgTermometroAmarelo.Bitmap;
  btnTempo.Bitmap := imgRelogioBranco.Bitmap;
  TabControlPrincipal.GoToVisibleTab(2);
end;


procedure TForm1.TThreadEnd(Sender: TObject);
begin
  if Assigned(TThread(Sender).FatalException) then
    ShowMessage(Exception(TThread(Sender).FatalException).Message);
end;


procedure TForm1.btnIniciarClick(Sender: TObject);
var
  t : TThread;
begin
  if lblConectar.text <> 'Forno conectado' then
    begin
      ShowMessage('Forno não conectado!' + sLineBreak + 'Se conecte a rede Wi-fi "FonoSolar" e depois clique no botão "Verificar Conexão".');
    end
  else
    begin
      if lblIniciar.Text = 'Cozinhar' then
        begin
          lblIniciar.Text := 'Finalizar';
          rctStatus.Fill.Color := laranja;
          lblStatus.Text := 'Esquentando...';

          t := TThread.CreateAnonymousThread(procedure
          var
            response: IResponse;
            responsePost: IResponse;
            dados: TJSONObject;
            temp: string;
            jsonStr: string;
            jsonObj : TJSONObject;
            i, j, k: integer;
            jsonTemps, jsonFinal: TJSONArray;
          begin
            try
              responsePost := TRequest.New.BaseURL('fornosolar.local/cozinhar')
                            .Accept('application/json')
                            .AddBody(lblSliderTemp.Text)
                            .Post;
            except
              TThread.Synchronize(nil, procedure
                begin
                  lblIniciar.Text := 'Cozinhar';
                  rctStatus.Fill.Color := vermelho;
                  lblStatus.Text := 'Desligado';
                  lblTemperatura.Text := '0';
                  lblConectar.Text := 'Forno não conectado';
                  ShowMessage('Erro ao enviar a temperatura!' + sLineBreak +
                  'Verifique se o dispositivo está conectado a rede "FornoSolar"');
                end);
            end;

            i := 1;
            jsonStr := '[';
            while lblIniciar.Text <> 'Cozinhar' do
            begin
              jsonTemps := TJSONArray.Create;
              jsonFinal := TJSONArray.Create;
              try
                response := TRequest.New.BaseURL('fornosolar.local/temperatura')
                          .Accept('application/json')
                          .Get;
              except
                TThread.Synchronize(nil, procedure
                begin
                  lblIniciar.Text := 'Cozinhar';
                  rctStatus.Fill.Color := vermelho;
                  lblStatus.Text := 'Desligado';
                  lblTemperatura.Text := '0';
                  lblConectar.Text := 'Forno não conectado';
                  ShowMessage('Erro ao se comunicar com o Forno!' + sLineBreak +
                  'Verifique se o dispositivo está conectado a rede "FornoSolar"');
                end);
              end;

              dados := TJsonObject.ParseJSONValue(TEncoding.UTF8.GetBytes(response.Content), 0) as TJSONObject;

              temp := dados.GetValue<string>('temperatura', '0');

              //ADICIONANDO LOG DAS TEMPERATURAS

              logGrafico.Lines.Add('Temperatura ' + i.ToString + ': ' + temp);

              //

              if i < 2 then
              begin
                jsonStr := jsonStr + '{"field":"' +
                      i.ToString +
                      '", "valor":' +
                      temp +
                      '}]';
              end
              else
              begin
                jsonStr := Copy(jsonStr, 1, (jsonStr.Length - 1));
                jsonStr := jsonStr + ', {"field":"' +
                      i.ToString +
                      '", "valor":' +
                      temp +
                      '}';

                jsonStr := jsonStr + ']';

                jsonTemps := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(jsonStr), 0) as TJSONArray;

                if i > 10 then
                begin
                  for j := (jsonTemps.Count - 10) to (jsonTemps.Count - 1) do
                  begin
                    jsonFinal.AddElement(jsonTemps.Items[j].Clone as TJSONObject);
                  end;

                  for k := 0 to 9 do
                  begin
                    jsonObj := jsonFinal.Items[k] as TJSONObject;
                    jsonObj.RemovePair('field');
                    jsonObj.AddPair('field', (k+1).ToString);
                  end;

                  TThread.Synchronize(nil, procedure
                  begin
                    montarGrafico(jsonFinal.ToString);
                  end);

                  jsonStr := jsonFinal.ToString;
                end
                else
                begin

                  TThread.Synchronize(nil, procedure
                  begin
                    montarGrafico(jsonStr);
                  end);

                end;
              end;



              TThread.Synchronize(nil, procedure
              begin
                lblTemperatura.Text := temp;
              end);

              i := i + 1;
              dados.Free;

              jsonTemps.Free;
              jsonFinal.Free;

              sleep(3000);
            end;
          end);

          t.Start;
          t.OnTerminate := TThreadEnd;
        end
      else if lblIniciar.Text = 'Finalizar' then
        begin
          lblIniciar.Text := 'Cozinhar';
          rctStatus.Fill.Color := vermelho;
          lblStatus.Text := 'Desligado';
          lblTemperatura.Text := '0';
        end;
    end;
end;

procedure TForm1.btnLimparClick(Sender: TObject);
begin
  logGrafico.Text := '';
end;

procedure TForm1.sldServoChange(Sender: TObject);
begin
 lblAngulo.Text := sldServo.Value.ToString;
end;

procedure TForm1.sldTempChange(Sender: TObject);
begin
  lblSliderTemp.Text := (200 - sldTemp.Value).ToString + ' °C';
end;

procedure TForm1.swtTempSwitch(Sender: TObject);
begin
  if TSwitch(Sender).IsChecked then
    begin
      sldTemp.Visible := False;
      lblSliderTemp.Text := 'MAX';
    end;


  if not TSwitch(Sender).IsChecked then
    begin
      sldTemp.Visible := True;
      lblSliderTemp.Text := (200 - sldTemp.Value).ToString + ' °C';
    end;


end;





{..................FUNCOES...............}

{function TForm1.CheckInternet: boolean;
var
  http: THTTPClient;
begin
  Result := false;

  try
    http := THTTPClient.Create;

    try
      Result := http.Head('192.168.4.1/conexao').StatusCode < 400;
    except
    end;
  finally
    http.Free;
  end;
end;}

end.
