// Saved panel addresses for central management ("Servers" page).
// Mirrors backend database/model/server.go; field names follow the JSON the
// API emits (lowercase first letter).
export interface Server {
  id?: number
  name: string
  url: string
  token?: string
  remark?: string
}
