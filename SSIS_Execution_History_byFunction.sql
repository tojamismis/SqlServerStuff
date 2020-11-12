
DECLARE @history TABLE
(
    project_name nvarchar(100),
    executable_name nvarchar(100),
    execution_path nvarchar(500),
    package_name nvarchar(100),
    execution_duration int,
    execution_count int,
    task_name nvarchar(100),
    parent_path nvarchar(500)
)

insert into @history
select 
	     project.[name] as [project_name]
          ,CASE WHEN LEN(executables.[executable_name]) <= 1024 THEN executables.[executable_name] ELSE LEFT(executables.[executable_name], 1024) + '...' END AS [executable_name]
          ,CASE WHEN LEN(executable_statistics.[execution_path]) <= 1024 THEN executable_statistics.[execution_path] ELSE LEFT(executable_statistics.[execution_path], 1024) + '...' END AS [execution_path]
          ,executables.[package_name]
          ,(CONVERT(FLOAT,AVG(executable_statistics.[execution_duration])/1000)) AS [execution_duration]
		,COUNT(executable_statistics.[execution_duration]) AS [execution_count]
		  ,reverse(left(reverse(executable_statistics.[execution_path]), charindex('\', reverse(executable_statistics.[execution_path])) -1)) AS [task_name]
		  ,SUBSTRING(executable_statistics.[execution_path], 0, 1 + LEN(executable_statistics.[execution_path]) - charindex('\', reverse(executable_statistics.[execution_path]))) AS [parent_path]
from catalog.projects project
    inner join catalog.packages package on package.project_id = project.project_id
    inner join catalog.executables executables on package.package_guid = executables.executable_guid
    inner join catalog.executable_statistics executable_statistics
	   ON executable_statistics.[execution_id] =executables.[execution_id] AND
          executable_statistics.[executable_id] =executables.[executable_id]
where project.[name] in ('ConvercentETL', 'Warehouse2StageETL', 'Warehouse2LoadETL')
GROUP BY project.[name],executables.executable_name, executable_statistics.execution_path, executables.package_name

select * from @history h
where h.execution_path not in (select parent_path from @history)
order by h.execution_duration desc;