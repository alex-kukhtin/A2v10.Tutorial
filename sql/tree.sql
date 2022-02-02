

------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'dbo' and TABLE_NAME=N'Agents')
begin
create table dbo.Agents 
(
	Id bigint constraint PK_Agents primary key,
	Parent bigint,
	[Name] nvarchar(255)
);
end
go

create or alter procedure dbo.[Agent.Index]
@UserId bigint
as
begin
	set nocount on;

	with T(Id, Parent, [Level])
	as (
		select Id, Parent, 0 from dbo.Agents a where a.Parent is null
		union all 
		select a.Id, a.Parent, T.[Level] + 1 
		from dbo.Agents a inner join T on T.Id = a.Parent
	)
	select [Agents!TAgent!Tree] = null, [Id!!Id] = a.Id, [!TAgent.Items!ParentId]=T.Parent,  [Name!!Name] = a.[Name],
		[Items!TAgent!Items] = null,
		[Level] = T.[Level]
	from dbo.Agents a inner join T on  a.Id = T.Id
	order by [Level], [Id!!Id];
end
go

create or alter procedure dbo.[Agent2.Index]
@UserId bigint
as
begin
	set nocount on;
	select [Agents!TAgent!Tree] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name],
		[Items!TAgent!Items] = null,
		[HasChildren!!HasChildren] = case when exists(select * from dbo.Agents c where c.Parent = a.Id) then 1 else 0 end
	from dbo.Agents a where Parent is null
	order by [Id!!Id];
end
go

create or alter procedure dbo.[Agent2.Expand]
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	select [Items!TAgent!Tree] = null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name],
		[Items!TAgent!Items] = null,
		[HasChildren!!HasChildren] = case when exists(select * from dbo.Agents c where c.Parent = a.Id) then 1 else 0 end
	from dbo.Agents a where Parent = @Id
	order by [Id!!Id];
end
go