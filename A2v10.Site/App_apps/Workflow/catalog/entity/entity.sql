use a2v10_tutorial
go

if not exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME = N'Entities' and TABLE_SCHEMA = N'a2tutorial')
begin
	create table a2tutorial.Entities (
		entId bigint identity(100,1) not null constraint PK_Entities primary key,
		entName nvarchar(128) not null,
		artNo nvarchar(50),
		barcode nvarchar(13),
		qrcode nvarchar(max),
		dateIn datetime,
		dateOut datetime,
		entType int,
		memo nvarchar(255)
		);
end;
go

--------------------------------
if exists(select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Entity.Index')
	drop proc a2tutorial.[Entity.Index]
go

create or alter proc a2tutorial.[Entity.Index]
	@UserId bigint
as
 begin
	set nocount on;
	set transaction isolation level read uncommitted;

	Select [Entities!TEntity!Array] = null, [Id!!Id] = entId, [Name] = entName, artNo, barcode, dateIn, memo
	from a2tutorial.Entities
	order by entId desc;
end;
go

-----------------------
create or alter proc a2tutorial.[Entity.Load]
	@UserId bigint,
	@Id bigint = null
as
 begin
	set nocount on;
	set transaction isolation level read uncommitted;

	Select [Entity!TEntity!Object] = null, [Id!!Id] = entId, [Name] = entName, artNo, barcode, dateIn, memo
	from a2tutorial.Entities
	where entId = @Id;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Entity.Metadata')
	drop procedure a2tutorial.[Entity.Metadata]
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Entity.Update')
	drop procedure a2tutorial.[Entity.Update]
go

-----------------------------
if exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2tutorial' and DOMAIN_NAME=N'Entity.TableType' and DATA_TYPE=N'table type')
	drop type a2tutorial.[Entity.TableType];
go
------------------------------------------------
create type a2tutorial.[Entity.TableType]
as table(
		entId bigint null,
		[Name] nvarchar(128) null,
		artNo nvarchar(50),
		barcode nvarchar(13),
		qrcode nvarchar(max),
		dateIn datetime,
		dateOut datetime,
		entType int,
		memo nvarchar(255)
)
go

CREATE OR ALTER procedure a2tutorial.[Entity.Metadata]
as
begin
	set nocount on;

	declare @Entity a2tutorial.[Entity.TableType];

	select [Entity!Entity!Metadata] = null, * from @Entity;
end
go

------------------------------------------------
CREATE OR ALTER procedure a2tutorial.[Entity.Update]
@UserId bigint,
@Entity a2tutorial.[Entity.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level serializable;
	set xact_abort on;

	declare @output table(op nvarchar(150), id bigint);

	merge a2tutorial.Entities as target
	using @Entity as source
	on (target.entId = source.entId)
	when matched then
		update set 
			target.[artNo] = source.[artNo],
			target.[entName] = source.[Name],
			target.barcode = source.barcode,
			target.[Memo] = source.[Memo],
			target.dateIn = source.dateIn
	when not matched by target then 
		insert (artNo, [entName], barcode, Memo, dateIn)
		values (artNo, [Name], barcode, Memo, dateIn)
	output 
		$action op,
		inserted.entId id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	exec a2tutorial.[Entity.Load] @UserId, @RetId;

end
go