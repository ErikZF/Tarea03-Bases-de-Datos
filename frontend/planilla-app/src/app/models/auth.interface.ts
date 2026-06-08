export interface LoginRequest {
  username: string;
  password: string;
  postInIP: string;
}

export interface LoginResponse {
  userId: number;
  username: string;
}
