#include <WiFi.h> //Inclui a biblioteca
#include <ESPmDNS.h>
#include <NetworkClient.h>
#include "max6675.h"
int temperatura;
int thermoDO = 6; //19
int thermoCS = 7; //23
int thermoCLK = 4; //5

MAX6675 thermocouple(thermoCLK, thermoCS, thermoDO);

const char* ssid = "FornoSolar"; //Define o nome do ponto de acesso
const char* pass = "12345678"; //Define a senha
 
WiFiServer sv(80); //Cria um servidor na porta 80

void setup() {
  Serial.begin(115200); //Inicia o monitor serial
  pinMode(0, OUTPUT);  //Define a porta 23 como saída
  delay(10);  //Atraso de 10 milissegundos

  Serial.println("\n"); //Pula uma linha
  WiFi.softAP(ssid, pass); //Inicia o ponto de acesso
  Serial.print("Se conectando a: "); //Imprime mensagem sobre o nome do ponto de acesso
  Serial.println(ssid);

  IPAddress ip = WiFi.softAPIP(); //Endereço de IP
  
  Serial.print("Endereço de IP: "); //Imprime o endereço de IP
  Serial.println(ip);

  sv.begin(); //Inicia o servidor 
  Serial.println("Servidor online"); //Imprime a mensagem de início

  if (!MDNS.begin("fornosolar")) {
    Serial.println("Error setting up MDNS responder!");
    while (1) {
      delay(1000);
    }
  }
  Serial.println("mDNS responder started");

  // Start TCP (HTTP) server
  Serial.println("TCP server started");

  // Add service to MDNS-SD
  MDNS.addService("http", "tcp", 80);
  //Serial.println("MAX6675 test");
  // wait for MAX chip to stabilize
  delay(500);
}




void loop() {
  //temperatura = random(0,101);
  // basic readout test, just print the current temp
  
  Serial.print("C = "); 
  //Serial.println(thermocouple.readCelsius());

  temperatura = thermocouple.readCelsius();


  
  // For the MAX6675 to update, you must delay AT LEAST 250ms between reads!
  delay(1000);
  //Serial.println("printando...");

  WiFiClient client = sv.available(); //Cria o objeto cliente

  if (client) { //Se este objeto estiver disponível
    String line = ""; //Variável para armazenar os dados recebidos

    while (client.connected()) { //Enquanto estiver conectado
      if (client.available()) { //Se estiver disponível
        char c = client.read(); //Lê os caracteres recebidos
        if (c == '\n') { //Se houver uma quebra de linha
          if (line.length() == 0) { //Se a nova linha tiver 0 de tamanho
            client.println("HTTP/1.1 200 OK"); //Envio padrão de início de comunicação
            client.println("Content-type:text/html");
            client.println();

            //client.print("teste"); //Linha para ligar o led
            //client.print("Desligue o led clicando <a href=\"/desligar\">aqui</a><br>"); //Linha para desligar o led

            client.println();
            break;
          } else {   
            line = "";
          }
        } else if (c != '\r') { 
          line += c; //Adiciona o caractere recebido à linha de leitura
        }
          
        if (line.endsWith("GET /ligar")) { //Se a linha terminar com "/ligar", liga o led
          digitalWrite(0, HIGH);
          client.println("HTTP/1.1 200 OK"); //Envio padrão de início de comunicação
          client.println("Content-type:text/html");
          client.println();
          client.print("teste ligar");
          break;               
        }
        if (line.endsWith("GET /desligar")) { //Se a linha terminar com "/desligar", desliga o led
          digitalWrite(0, LOW);  
          client.println("HTTP/1.1 200 OK"); //Envio padrão de início de comunicação
          client.println("Content-type:text/html");
          client.println();
          client.print("teste desligar");
          break;                
        }
        if (line.endsWith("GET /temperatura")) {  
          client.println("HTTP/1.1 200 OK"); //Envio padrão de início de comunicação
          client.println("Content-type:application/json");
          client.println();
          client.print("{\"temperatura\": \"" + String(temperatura) +"\"}");
          break;                
        }
        if (line.endsWith("GET /conexao")) {  
          client.println("HTTP/1.1 200 OK"); //Envio padrão de início de comunicação
          client.println("Content-type:text/html");
          client.println();
          client.print("Servidor online!!");
          break;                
        }
        if (line.endsWith("POST /cozinhar")) {  
          String postBody = client.readString();
          Serial.println(postBody);
          client.println("HTTP/1.1 200 OK"); //Envio padrão de início de comunicação
          client.println("Content-type:text/html");
          client.println();
          client.print("Post em /cozinhar recebido.");
          break;                
        }
      }
    }

    client.stop(); //Para o cliente
  }
}