
SINCRONISMO
-----------
toda 2a terca-feira do mes microsoft disponibiliza patchs
agendar rotina para sincronizar wsus com a microsoft toda 2a quarta-feira do mes


IMAGENS
-------
atualizacao das imagens windows (escolher mensal, bimestral, trimestral, etc, dependendo da norma e processo)
publicar imagens somente apos aplicacao e validacao no ambiente DEV/HOM
opcao de manter ultima e penultima imagem


AMBIENTE DEV 
------------
puppet forca apontamento para wsus dev e horario auto install e boot as 23h 
WSUS AUTO APROVE para grupo START-DEV 
rotina a cada 1h, toda nova instancia, atribuir no grupo START-DEV
todas instancias serao atualizadas automaticamente com todos os patchs as 23h


AMBIENTE PROD
-------------
puppet forca apontamento para wsus dev e horario auto install e boot (ctsp=0h, ctmm1=1h, ctmm2=2h)
na data escolhida, abre gmud por site
chama rotina para preparar gmud wsus
- recebe gmud e site como parametro
- consulta e valida informacoes da gmud
- cria grupo da gmud no wsus
- atribui grupo da gmud para todas as instancias
- gera lista das instancias por gmud (com qtde patchs necessarios se possivel) na pasta processando
- gera hmtl das instancias por gmud (com qtde patchs necessarios se possivel) na pasta processando
todas instancias serao atualizadas automaticamente com todos os patchs no seu respectivo horario do site


ACOMPANHAMENTO GMUD
-------------------
rotina agendada para rodar entre 23h e 06h
consulta arquivo gmud na pasta processando (significa gmud em andamento)
- gera lista das instancias do grupo gmud (com qtde patchs necessarios se possivel) na pasta acompanhamento
- gera hmtl das instancias do grupo gmud (com qtde patchs necessarios se possivel) na pasta acompanhamento
- remove do grupo as instancias 100% atualizadas ou a cada execucao ou no final numa rotina de fechamento
- postar metricas no grafana:
    - <site>.<ambiente>.WSUS.aplicapatch.<gmud>.totalcomputers
    - <site>.<ambiente>.WSUS.aplicapatch.<gmud>.neededupdates
    - <site>.<ambiente>.WSUS.aplicapatch.<gmud>.failures
    - <site>.<ambiente>.WSUS.aplicapatch.<gmud>.atualizadas
    - <site>.<ambiente>.WSUS.aplicapatch.<gmud>.pendingreboot


FINALIZA GMUD
-------------
fechamento da gmud se possivel no maximo
move todos os arquivos da pasta processando para fechadas
remove todas as instancias do grupo gmud do wsus
remove grupo da gmud


FORCA UPDATE
------------
rotina para forcar wsus cliente download, install, update, boot
executada manualmente ou agendada lendo as instancias pendentes



BATIMENTO OPENSTACK X WSUS
--------------------------
extrai lista de instancias do openstack
pesquisa no wsus
se nao encontra, cria lista inconsistencia openstack x wsus, gera html


BATIMENTO OPENSTACK X ASSET
--------------------------
extrai lista de instancias do openstack
pesquisa no asset
se nao encontra, cria lista inconsistencia openstack x asset, gera html
