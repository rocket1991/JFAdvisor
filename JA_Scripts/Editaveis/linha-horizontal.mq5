//--- descrição
#property description "Script desenha o objeto gráfico \"Linha Horizontal\"."
#property description "Ponto de ancoragem do preço está definido em percentagem da altura do"
#property description "janela do gráfico."
//--- janela de exibição dos parâmetros de entrada durante inicialização do script
#property script_show_inputs
//--- entrada de parâmetros do script
input string          InpName="HLine";     // Nome da linha
input int             InpPrice=25;         // Preço da linha, %
input color           InpColor=clrRed;     // Cor da linha
input ENUM_LINE_STYLE InpStyle=STYLE_DASH; // Estilo da linha
input int             InpWidth=3;          // Largura da linha
input bool            InpBack=false;       // Linha de fundo
input bool            InpSelection=true;   // Destaque para mover
input bool            InpHidden=true;      // Ocultar na lista de objeto
input long            InpZOrder=0;         // Prioridade para clicar no mouse
//+------------------------------------------------------------------+
//| Criar a linha horizontal                                         |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // ID de gráfico
                 const string          name="HLine",      // nome da linha
                 const int             sub_window=0,      // índice da sub-janela
                 double                price=0,           // line price
                 const color           clr=clrRed,        // cor da linha
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // estilo da linha
                 const int             width=1,           // largura da linha
                 const bool            back=false,        // no fundo
                 const bool            selection=true,    // destaque para mover
                 const bool            hidden=true,       //ocultar na lista de objetos
                 const long            z_order=0)         // prioridade para clique do mouse
  {
//--- se o preço não está definido, defina-o no atual nível de preço Bid
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- redefine o valor de erro
   ResetLastError();
//--- criar um linha horizontal
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,0,0,price))
     {
      Print(__FUNCTION__,
            ": falha ao criar um linha horizontal! Código de erro = ",GetLastError());
      return(false);
     }
//--- definir cor da linha
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- definir o estilo de exibição da linha
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- definir a largura da linha
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- exibir em primeiro plano (false) ou fundo (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- habilitar (true) ou desabilitar (false) o modo do movimento da seta com o mouse
//--- ao criar um objeto gráfico usando a função ObjectCreate, o objeto não pode ser
//--- destacado e movimentado por padrão. Dentro deste método, o parâmetro de seleção
//--- é verdade por padrão, tornando possível destacar e mover o objeto
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- ocultar (true) ou exibir (false) o nome do objeto gráfico na lista de objeto 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- definir a prioridade para receber o evento com um clique do mouse no gráfico
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- sucesso na execução
   return(true);
  }
//+------------------------------------------------------------------+
//| Mover linha horizontal                                           |
//+------------------------------------------------------------------+
bool HLineMove(const long   chart_ID=0,   // ID do gráfico
               const string name="HLine", // nome da linha
               double       price=0)      // preço da linha
  {
//--- se o preço não está definido, defina-o no atual nível de preço Bid
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- redefine o valor de erro
   ResetLastError();
//--- mover um linha horizontal 
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": falha ao mover um linha horizontal! Código de erro = ",GetLastError());
      return(false);
     }
//--- sucesso na execução
   return(true);
  }
//+------------------------------------------------------------------+
//| Excluir uma linha horizontal                                     |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // ID do gráfico
                 const string name="HLine") // nome da linha
  {
//--- redefine o valor de erro
   ResetLastError();
//--- excluir uma linha horizontal
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": falha ao Excluir um linha horizontal! Código de erro = ",GetLastError());
      return(false);
     }
//--- sucesso na execução
   return(true);
  }
//+------------------------------------------------------------------+
//| Programa Script da função start (iniciar)                        |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- verificar a exatidão dos parâmetros de entrada
   if(InpPrice<0 || InpPrice>100)
     {
      Print("Erro! Valores incorretos dos parâmetros de entrada!");
      return;
     }
//--- tamanho do array de preço
   int accuracy=1000;
//--- array para armazenar data de valores a serem utilizados
//--- para definir e alterar as coordenadas de pontos de ancoragem
   double price[];
//--- alocação de memória
   ArrayResize(price,accuracy);
//--- preencher o array de preços
//--- encontrar os maiores e menores valores do gráfico
   double max_price=ChartGetDouble(0,CHART_PRICE_MAX);
   double min_price=ChartGetDouble(0,CHART_PRICE_MIN);
//--- definir uma etapa de mudança de um preço e preencher o array
   double step=(max_price-min_price)/accuracy;
   for(int i=0;i<accuracy;i++)
      price[i]=min_price+i*step;
//--- definir os pontos para desenhar a linha
   int p=InpPrice*(accuracy-1)/100;
//--- criar um linha horizontal
   if(!HLineCreate(0,InpName,0,price[p],InpColor,InpStyle,InpWidth,InpBack,
      InpSelection,InpHidden,InpZOrder))
     {
      return;
     }
//--- redesenhar o gráfico e esperar por um segundo
   ChartRedraw();
   Sleep(1000);
//--- agora, mover a linha
//--- contador de loop
   int v_steps=accuracy/2;
//--- mover a linha
   for(int i=0;i<v_steps;i++)
     {
      //--- usar o seguinte valor
      if(p<accuracy-1)
         p+=1;
      //--- mover o ponto
      if(!HLineMove(0,InpName,price[p]))
         return;
      //--- verificar se o funcionamento do script foi desativado a força
      if(IsStopped())
         return;
      //--- redesenhar o gráfico
      ChartRedraw();
     }
//--- 1 segundo de atraso
   Sleep(1000);
//--- excluir a partir do gráfico
   HLineDelete(0,InpName);
   ChartRedraw();
//--- 1 segundo de atraso
   Sleep(1000);
//---
  }