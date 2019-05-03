------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2tutorial' and SEQUENCE_NAME=N'SQ_Agents')
	create sequence a2tutorial.SQ_Agents as bigint start with 100 increment by 1;
go
------------------------------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2tutorial' and TABLE_NAME=N'Agents')
begin
	create table a2tutorial.Agents
	(
		Id	bigint not null constraint PK_Agents primary key
			constraint DF_Agents_PK default(next value for a2tutorial.SQ_Agents),
		[Code] nvarchar(32) null,
		[Name] nvarchar(255) null,
		[Memo] nvarchar(255) null,
		-- полезные поля
		DateCreated datetime not null constraint DF_Agents_DateCreated default(getutcdate()),
		UserCreated bigint not null
			constraint FK_Agents_UserCreated_Users foreign key references a2security.Users(Id),
		DateModified datetime not null constraint DF_Agents_DateModified default(getutcdate()),
		UserModified bigint not null
			constraint FK_Agents_UserModified_Users foreign key references a2security.Users(Id)
	);
end
go
------------------------------------------------
create or alter procedure a2tutorial.[Agent.Index]
@UserId bigint
as
begin
	set nocount on;
	select [Agents!TAgent!Array] = null, [Id!!Id] = Id, [Name], Code, Memo
	from a2tutorial.Agents
	order by Id;
end
go
------------------------------------------------
create or alter procedure a2tutorial.[Agent.Load]
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	select [Agent!TAgent!Object] = null, [Id!!Id] = Id, [Name], Code, Memo
	from a2tutorial.Agents
	where Id=@Id;
end
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Agent.Metadata')
	drop procedure a2tutorial.[Agent.Metadata]
go
------------------------------------------------
if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2tutorial' and ROUTINE_NAME=N'Agent.Update')
	drop procedure a2tutorial.[Agent.Update]
go
------------------------------------------------
if exists(select * from INFORMATION_SCHEMA.DOMAINS where DOMAIN_SCHEMA=N'a2tutorial' and DOMAIN_NAME=N'Agent.TableType' and DATA_TYPE=N'table type')
	drop type a2tutorial.[Agent.TableType];
go
------------------------------------------------
create type a2tutorial.[Agent.TableType]
as table(
	Id bigint null,
	Code nvarchar(32),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
------------------------------------------------
create or alter procedure a2tutorial.[Agent.Metadata]
as
begin
	set nocount on;
	declare @Agent a2tutorial.[Agent.TableType];
	select [Agent!Agent!Metadata]=null, * from @Agent;
end
go
------------------------------------------------
create procedure a2tutorial.[Agent.Update]
	@UserId bigint,
	@Agent a2tutorial.[Agent.TableType] readonly,
	@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;

	declare @output table(op sysname, id bigint);


	merge a2tutorial.Agents as target
	using @Agent as source
	on (target.Id = source.Id)
	when matched then
		update set 
			target.[Name] = source.[Name],
			target.[Code] = source.[Code],
			target.[Memo] = source.Memo,
			target.[DateModified] = getdate(),
			target.[UserModified] = @UserId
	when not matched by target then 
		insert ([Name], [Code], Memo, UserCreated, UserModified)
		values ([Name], [Code], Memo, @UserId, @UserId)

	output 
		$action op,
		inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	exec a2tutorial.[Agent.Load] @UserId, @RetId;
end
go

