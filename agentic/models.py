from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class GithubRepo(BaseModel):
    owner: str
    repo: str

class Source(BaseModel):
    name: str
    id: str
    github_repo: GithubRepo = Field(..., alias="githubRepo")

class ListSourcesResponse(BaseModel):
    sources: List[Source]
    next_page_token: Optional[str] = Field(None, alias="nextPageToken")

class GithubRepoContext(BaseModel):
    starting_branch: Optional[str] = Field(None, alias="startingBranch")

class SourceContext(BaseModel):
    source: str
    github_repo_context: Optional[GithubRepoContext] = Field(None, alias="githubRepoContext")

class CreateSessionRequest(BaseModel):
    prompt: str
    source_context: SourceContext = Field(..., alias="sourceContext")
    title: str
    require_plan_approval: Optional[bool] = Field(None, alias="requirePlanApproval")
    automation_mode: Optional[str] = Field(None, alias="automationMode")

class Session(BaseModel):
    name: str
    id: str
    title: str
    source_context: SourceContext = Field(..., alias="sourceContext")
    prompt: str

class ListSessionsResponse(BaseModel):
    sessions: List[Session]
    next_page_token: Optional[str] = Field(None, alias="nextPageToken")

class SendMessageRequest(BaseModel):
    prompt: str

class Activity(BaseModel):
    name: str
    type: str
    content: Dict[str, Any]
    create_time: str = Field(..., alias="createTime")

class ListActivitiesResponse(BaseModel):
    activities: List[Activity]
    next_page_token: Optional[str] = Field(None, alias="nextPageToken")
