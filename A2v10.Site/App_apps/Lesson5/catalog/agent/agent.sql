-----------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = N'Images' and TABLE_SCHEMA = N'a2tutorial')
begin
	create table a2tutorial.Images (
		Id bigint identity(100, 1) not null constraint PK_Images primary key,
		[Name] nvarchar(255),
		[Mime] nvarchar(255),
		[Stream] varbinary(max)
	)
end
go
-----------------------------
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = N'Agents' and TABLE_SCHEMA = N'a2tutorial')
begin
	create table a2tutorial.Agents (
		Id bigint identity(100, 1) not null constraint PK_Agents primary key,
		Code nvarchar(32),
		[Name] nvarchar(255),
		[Memo] nvarchar(255),
		[BirthDay] datetime,
		[Image] bigint null constraint FK_Agents_Image_Images foreign key references a2tutorial.Images(Id)
	)
end
go
------------------------------------------------
if (not exists (select 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2tutorial' and TABLE_NAME=N'Agents' and COLUMN_NAME=N'Image'))
begin
	alter table a2tutorial.Agents add [Image] bigint null constraint FK_Agents_Image_Images foreign key references a2tutorial.Images(Id);
end
go
------------------------------------------------
if (not exists (select 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA=N'a2tutorial' and TABLE_NAME=N'Agents' and COLUMN_NAME=N'BirthDay'))
begin
	alter table a2tutorial.Agents add [BirthDay] datetime null;
end
go
-----------------------------
create or alter procedure a2tutorial.[Agent.Index]
@UserId bigint = null,
@Id bigint = null,
@Name nvarchar(255) = null,
@Memo nvarchar(255) = null,
@Offset int = 0,
@PageSize int = 10,
@Order nvarchar(255) = N'Id',
@Dir nvarchar(20) = N'desc'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;
	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = isnull(@Dir, @Asc);

	select [Agents!TAgent!Array] = null, [Id!!Id] = Id, Code, [Name], Memo, BirthDay,
			[!!RowNumber] = row_number() over (
			 order by
				case when @Order=N'Id' and @Dir = @Asc then a.Id end asc,
				case when @Order=N'Id' and @Dir = @Desc  then a.Id end desc,
				case when @Order=N'Memo' and @Dir = @Asc then a.Memo end asc,
				case when @Order=N'Memo' and @Dir = @Desc then a.Memo end desc,
				case when @Order=N'Name' and @Dir = @Asc then a.[Name] end asc,
				case when @Order=N'Name' and @Dir = @Desc then a.[Name] end desc
			),
			[!!RowCount] = count(*) over ()
	from a2tutorial.Agents a
		where isnull(@Name, N'') = N'' and isnull(@Memo, N'') = N'' or  
			(upper([Name]) like N'%' + upper(@Name) + N'%' or upper([Memo]) like N'%' + upper(@Memo))
	order by [!!RowNumber] offset (@Offset) rows fetch next (@PageSize) rows only;

	select [!$System!] = null, 
		[!Agents!PageSize] = @PageSize, 
		[!Agents!SortOrder] = @Order, 
		[!Agents!SortDir] = @Dir,
		[!Agents!Offset] = @Offset,
		[!Agents.Name!Filter] = @Name,
		[!Agents.Memo!Filter] = @Memo;
end
go
-----------------------------
create or alter procedure a2tutorial.[Agent.Load]
@UserId bigint,
@Id bigint = null,
@Text nvarchar(255) = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Agent!TAgent!Object] = null, [Id!!Id] = Id, Code, [Name], Memo, BirthDay,
		[Image]
	from a2tutorial.Agents
	where Id=@Id;

	select [Params!TParam!Object] = null, [Text] = @Text;
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
	[Memo] nvarchar(255),
	BirthDay datetime,
	[Image] bigint
)
go
------------------------------------------------
create or alter procedure a2tutorial.[Agent.Metadata]
as
begin
	set nocount on;
	declare @Agent a2tutorial.[Agent.TableType];
	select [Agent!Agent!Metadata] = null, * from @Agent;
end
go
------------------------------------------------
create or alter procedure a2tutorial.[Agent.Update]
@UserId bigint,
@Agent a2tutorial.[Agent.TableType] readonly,
@RetId bigint = null output
as
begin
	set nocount on;
	set transaction isolation level serializable;
	set xact_abort on;

	declare @output table(op nvarchar(150), id bigint);

	merge a2tutorial.Agents as target
	using @Agent as source
	on (target.Id = source.Id)
	when matched then
		update set 
			target.[Code] = source.[Code],
			target.[Name] = source.[Name],
			target.[Memo] = source.[Memo],
			target.BirthDay = source.BirthDay,
			target.[Image] = nullif(source.[Image], 0)
	when not matched by target then 
		insert ([Code], [Name], Memo, BirthDay, [Image])
		values ([Code], [Name], Memo, BirthDay, nullif([Image], 0))
	output 
		$action op,
		inserted.Id id
	into @output(op, id);

	select top(1) @RetId = id from @output;

	exec a2tutorial.[Agent.Load] @UserId, @RetId;

end
go

create or alter procedure a2tutorial.[Agent.Delete]
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	set transaction isolation level serializable;
	set xact_abort on;
	throw 60000, N'UI:Не можна видаляти. Вам цього неможна', 0;
	delete from a2tutorial.Agents where Id=@Id;
end
go
--insert into a2tutorial.Agents(Code, [Name]) values (N'1', N'First')
 

create or alter procedure a2tutorial.[Supplier.Fetch]
	@UserId bigint,
	@Text nvarchar(255) = null
as
begin
	set nocount on
	set nocount on;
	set transaction isolation level read uncommitted;

	if @Text is not null
		set @Text = N'%' + upper(@Text) + N'%';

	select [Agents!TAgent!Array]=null, [Id!!Id] = a.Id, [Name!!Name] = a.[Name], Code, a.Memo
	from a2tutorial.Agents a
		where (upper(a.[Name]) like @Text or upper(a.[Code]) like @Text
			or upper(a.Memo) like @Text or cast(a.Id as nvarchar) like @Text)
	order by a.[Name]
end
go
-----------------------------
create or alter procedure a2tutorial.[Agent.Image.Load]
@UserId bigint,
@Id bigint,
@Key nvarchar(255)
as
begin
	set nocount on;
	select Mime, Stream, [Name] from a2tutorial.Images where Id=@Id;
end
go
-----------------------------
create or alter procedure a2tutorial.[Agent.Image.Update]
	@UserId bigint,
	@Id bigint,
	@Key nvarchar(255),
	@Mime nvarchar(255),
	@Name nvarchar(255),
	@Stream varbinary(max),
	@RetId bigint output
as
begin
	set nocount on;
	declare @rt table(Id bigint);
	update a2tutorial.Images set Stream=@Stream, [Name] = @Name, Mime = @Mime where Id=@Id;
	if @@ROWCOUNT = 0
	begin
		insert into a2tutorial.Images (Stream, [Name], Mime) 
			output inserted.Id into @rt(Id)
			values (@Stream, @Name, @Mime);
		select @RetId = Id from @rt;
	end
	else
		set @RetId = @Id;
end
go

create or alter procedure a2tutorial.[Agent.List.Load]
@UserId bigint,
@Id bigint = 0,
@From datetime = null,
@To datetime = null
as
begin
	select [Agents!TAgent!Array] = null, [Id!!Id] = Id, Code, [Name], Memo, BirthDay
	from a2tutorial.Agents a
	order by Id desc;

	select [Query!TQuery!Object] = null,
		[Period.From!TPeriod] = @From,
		[Period.To!TPeriod] = @To
end
go

