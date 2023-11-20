CREATE DATABASE REFERA;
USE REFERA;

-- Valor total das vendas e dos fretes por produto e ordem de venda
SELECT 
	 detalhes.ProdutoID
	,produto
	,cabecalho.CupomID AS OrdemVenda
	,SUM(detalhes.Valor) OVER(PARTITION BY  produtos.produtoID)  AS ValorTotal_Produto
	,SUM(cabecalho.ValorFrete)   OVER(PARTITION BY  produtos.produtoID) AS FreteTotal_Produto
	,SUM(detalhes.Valor) OVER(PARTITION BY  cabecalho.CupomID)  AS ValorTotal_OrdemVenda
	,SUM(cabecalho.ValorFrete)   OVER(PARTITION BY  cabecalho.CupomID) AS FreteTotal_OrdemVenda
FROM 
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
JOIN 
	[dbo].[fatoCabecalho] AS cabecalho
	ON
	cabecalho.CupomID = detalhes.CupomID
JOIN
	[dbo].[produtos] AS produtos
	ON
	detalhes.produtoID = produtos.produtoID
ORDER BY
	 produtos.produto
	,cabecalho.CupomID
-- Valor de venda por tipo de produto

SELECT 
	 categorias.Categoria
	,SUM(detalhes.Valor) AS TotalCategoria
FROM 
	[dbo].[categorias] AS categorias
JOIN
	[dbo].[produtos] AS produtos
ON 
	produtos.CategoriaID = categorias.CategoriaID
JOIN
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
ON
	detalhes.ProdutoID = produtos.ProdutoID
GROUP BY
	categorias.Categoria

-- Quantidade e valor das vendas por dia, mês, ano;

SELECT DISTINCT 
	 YEAR(cabecalho.Data) AS Ano
	,FORMAT(cabecalho.Data, 'MMMM') AS Mes
	,DAY(cabecalho.Data) AS Dia
	,COUNT(detalhes.CupomID) OVER(PARTITION BY YEAR(cabecalho.Data)) AS QuantidadeVendas_Ano
	,SUM(detalhes.Valor) OVER(PARTITION BY YEAR(cabecalho.Data)) AS ValorVendas_Ano
	,COUNT(detalhes.CupomID) OVER(PARTITION BY YEAR(cabecalho.Data), MONTH(cabecalho.Data)) AS QuantidadeVendas_Mes
	,SUM(detalhes.Valor) OVER(PARTITION BY MONTH(cabecalho.Data)) AS ValorVendas_Mes
	,COUNT(detalhes.CupomID) OVER(PARTITION BY YEAR(cabecalho.Data), DAY(cabecalho.Data)) AS QuantidadeVendas_Dia
	,SUM(detalhes.Valor) OVER(PARTITION BY DAY(cabecalho.Data)) AS ValorVendas_Dia
FROM  
	[dbo].[fatoCabecalho] AS cabecalho
JOIN
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
ON
	cabecalho.CupomID = detalhes.CupomID

-- Lucro dos meses
SELECT 
	  YEAR(cabecalho.Data) AS Ano
	 ,FORMAT(cabecalho.Data, 'MMMM') AS Mes
	 ,CONVERT(DECIMAL(10,2), SUM(detalhes.ValorLiquido) - SUM(funcionarios.SalarioAnual)/12) AS lucro
FROM 
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
JOIN
	[dbo].[fatoCabecalho] AS cabecalho
ON
	cabecalho.CupomID = detalhes.CupomID
JOIN
	[dbo].[funcionarios] AS funcionarios
ON
	funcionarios.FuncionarioID = cabecalho.FuncionarioID
GROUP BY
	 YEAR(cabecalho.Data)
	,FORMAT(cabecalho.Data, 'MMMM')
ORDER BY
	 Ano
	,Mes

-- Venda por produto
SELECT
	 produtos.ProdutoID
	,produtos.Produto
	,COUNT(CupomID) AS QuantidadeVendas
	,SUM(detalhes.Valor) AS totalVendas_produto
FROM 
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
JOIN
	[dbo].[produtos] AS produtos
ON
	produtos.ProdutoID = detalhes.ProdutoID
GROUP BY
	 produtos.ProdutoID
	,produtos.Produto

-- Venda por Cliente, cidade do cliente e Estado;
SELECT DISTINCT
	 clientes.ClienteID
	,clientes.Cidade 
	,COUNT(cabecalho.CupomID) OVER(PARTITION BY clientes.ClienteID) AS VendasCliente
	,COUNT(cabecalho.CupomID) OVER(PARTITION BY clientes.Cidade) AS VendasCidadeCliente
FROM 
	[dbo].[fatoCabecalho] AS cabecalho
JOIN
	[dbo].[clientes] AS clientes
ON
	cabecalho.ClienteID = clientes.ClienteID
JOIN
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
ON
	detalhes.CupomID = cabecalho.CupomID
ORDER BY
	clientes.cidade
-- Média de produtos vendidos

SELECT 
	AVG(media) AS media_produtos_vendidos
FROM (
    SELECT 
		COUNT(detalhes.ProdutoID) OVER (PARTITION BY CupomID) AS media
    FROM
		[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
) AS subconsulta;

-- Média de compras que um cliente faz
SELECT DISTINCT
	 clientes.ClienteID
	,CONVERT(DECIMAL(10,2), AVG(detalhes.Valor) OVER(PARTITION BY clientes.ClienteID)) AS MediaCompra 
FROM 
	[dbo].[FatoDetalhes_DadosModelagem] AS detalhes
JOIN 
	[dbo].[fatoCabecalho] AS cabecalho
ON
	cabecalho.CupomID = detalhes.CupomID
JOIN
	[dbo].[clientes] AS clientes
ON
	clientes.ClienteID = cabecalho.ClienteID