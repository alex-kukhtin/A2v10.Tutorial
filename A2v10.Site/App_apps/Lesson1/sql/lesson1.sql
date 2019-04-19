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

