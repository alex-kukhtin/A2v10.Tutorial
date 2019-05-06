--------------------------------
create or alter procedure a2tutorial.[Inbox.Index]
@UserId bigint
as
begin
	set nocount on;
	select [Inboxes!TInbox!Array] = null, [Id!!Id] = i.Id, [DateCreated], ProcessId, Bookmark, [Text]
	from a2workflow.Inbox i
	where Void=0
	order by i.Id desc;
end
go

--------------------------------
create or alter procedure a2tutorial.[Inbox.Load]
@UserId bigint,
@Id bigint
as
begin
	set nocount on;
	select [Inbox!TInbox!Object] = null, [Id!!Id] = i.Id, [DateCreated], ProcessId, Bookmark, [Text]
	from a2workflow.Inbox i
	where Id=@Id;

	declare @Wfid uniqueidentifier;
	select @Wfid = p.WorkflowId
	from a2workflow.Processes p inner join a2workflow.Inbox i on p.Id = i.ProcessId
	where i.Id = @Id;

	select [Log!TLogEntry!Array] = null, Id, RecordNumber, Content
	from a2workflow.[Log]
	where 
	WorkflowId = @Wfid
	order by RecordNumber
end
go
